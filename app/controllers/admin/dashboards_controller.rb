# app/controllers/admin/dashboards_controller.rb
module Admin
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def show
      @kpis = {
        active_listings: Listing.where(status: %w[approved published active]).count,
        private_sellers: User.where(role: :seller).count,
        estate_agents:   User.where(role: :estate_agent).count,
        open_tickets:    Ticket.where(status: :open).count,
        tickets_sla_breach: Ticket.where(status: :open).where("updated_at < ?", 48.hours.ago).count
      }

      # --- Private sellers with listings ---
      sellers_scope = User.where(role: :seller)
                          .left_joins(:listings)
                          .where.not(listings: { id: nil })
                          .distinct
      if params[:q].present?
        q = "%#{params[:q].downcase}%"
        sellers_scope = sellers_scope.where("LOWER(users.full_name) LIKE ? OR LOWER(users.email) LIKE ?", q, q)
      end
      @private_sellers = sellers_scope.order(created_at: :desc).limit(10)

      # --- Estate agents ---
      @estate_agents = User.where(role: :estate_agent).order(created_at: :desc).limit(50)

      # --- All users (role + search) ---
      @all_users = begin
        scope = User.all
        if params[:role].present?
          allowed = %w[buyer seller estate_agent admin]
          role = params[:role].to_s
          scope = scope.where(role: role) if allowed.include?(role)
        end
        if params[:q].present?
          q = "%#{params[:q].downcase}%"
          scope = scope.where("LOWER(users.full_name) LIKE ? OR LOWER(users.email) LIKE ?", q, q)
        end
        scope.order(created_at: :desc).limit(100)
      end
      # Tickets for dashboard tab
        @tickets = begin
          scope = Ticket.order(updated_at: :desc)

          # status filter (open/pending/closed)
          if params[:t_status].present?
            scope = scope.where(status: params[:t_status])
          end

          # search subject or requester email
          if params[:t_q].present?
            q = "%#{params[:t_q].downcase}%"
            scope = scope.left_joins(:user)
                        .where("LOWER(tickets.subject) LIKE ? OR LOWER(users.email) LIKE ?", q, q)
          end

          scope.limit(60)
        end
      # --- All listings (seller type + search) ---
      @all_listings = begin
        scope = Listing.includes(:user).order(created_at: :desc)
        case params[:seller_type].to_s
        when "private"      then scope = scope.joins(:user).where(users: { role: :seller })
        when "estate_agent" then scope = scope.joins(:user).where(users: { role: :estate_agent })
        end
        if params[:q].present?
          q = "%#{params[:q].downcase}%"
          scope = scope.where("LOWER(listings.title) LIKE ? OR LOWER(listings.address) LIKE ?", q, q)
        end
        scope.limit(100)
      end

      # --- Approvals / requests ---
      @pending_listings = Listing.where(status: :pending).order(created_at: :asc).limit(100)
      @agent_requests   = User.where(role: :seller, requested_estate_agent: true).order(updated_at: :asc).limit(100)

      @properties = Listing.order(updated_at: :desc).limit(100)
      @tickets    = Ticket.order(updated_at: :desc).limit(100)

      # ----------------------------------------------------------------
      # AUDIT & ACTIVITY FEED
      # Params expected from the audit filter form:
      #   from(YYYY-MM-DD), to(YYYY-MM-DD), atype(listing|user|ticket|other), q(text)
      # ----------------------------------------------------------------
      from  = params[:from].present? ? Time.zone.parse(params[:from]) : 7.days.ago
      to    = params[:to].present?   ? Time.zone.parse(params[:to]).end_of_day : Time.zone.now
      atype = params[:atype].presence
      qtxt  = params[:q].to_s.strip.downcase

      @audit_rows =
        if defined?(PublicActivity::Activity)
          scope = PublicActivity::Activity.where(created_at: from..to).order(created_at: :desc).limit(200)
          scope = scope.where(trackable_type: atype.classify) if %w[listing user ticket].include?(atype.to_s)
          rows = scope.map do |a|
            actor = a.owner
            track = a.trackable
            {
              time: a.created_at,
              actor_name: actor.try(:full_name) || actor.try(:email) || "System",
              actor_email: actor.try(:email),
              verb: a.key.to_s.split(".").last, # e.g. "update"
              target_type: a.trackable_type,
              target_label: (track.respond_to?(:title) ? track.title : "#{a.trackable_type}##{a.trackable_id}"),
              target_path: (track ? (polymorphic_path(track) rescue nil) : nil),
              details: (a.parameters.present? ? a.parameters.to_json : nil)
            }
          end
          rows
        elsif defined?(Audited) && defined?(Audited::Audit)
          scope = Audited::Audit.where(created_at: from..to).order(created_at: :desc).limit(200)
          scope = scope.where(auditable_type: atype.classify) if %w[listing user ticket].include?(atype.to_s)
          scope.map do |a|
            tgt = a.auditable
            {
              time: a.created_at,
              actor_name: a.user.try(:full_name) || a.user.try(:email) || "System",
              actor_email: a.user.try(:email),
              verb: a.action, # create/update/destroy
              target_type: a.auditable_type,
              target_label: tgt ? (tgt.respond_to?(:title) ? tgt.title : "#{a.auditable_type}##{a.auditable_id}") : "#{a.auditable_type}##{a.auditable_id}",
              target_path: (tgt ? (polymorphic_path(tgt) rescue nil) : nil),
              details: a.audited_changes.present? ? a.audited_changes.to_json.truncate(180) : nil
            }
          end
        else
          # Fallback: synthesize a recent activity feed from common models
          rows = []
          Listing.where(updated_at: from..to).order(updated_at: :desc).limit(80).each do |l|
            rows << {
              time: l.updated_at,
              actor_name: l.user&.full_name || l.user&.email || "User",
              actor_email: l.user&.email,
              verb: l.previous_changes.key?("id") && l.previous_changes["id"].first.nil? ? "created" : "updated",
              target_type: "Listing",
              target_label: l.title,
              target_path: listing_path(l),
              details: l.previous_changes.except(:updated_at).keys.take(5).join(", ").presence
            }
          end
          User.where(updated_at: from..to).order(updated_at: :desc).limit(60).each do |u|
            rows << {
              time: u.updated_at,
              actor_name: "System",
              actor_email: nil,
              verb: u.previous_changes.key?("id") && u.previous_changes["id"].first.nil? ? "created" : "updated",
              target_type: "User",
              target_label: u.full_name.presence || u.email,
              target_path: admin_user_path(u),
              details: u.previous_changes.except(:updated_at, :encrypted_password).keys.take(5).join(", ").presence
            }
          end
          Ticket.where(updated_at: from..to).order(updated_at: :desc).limit(60).each do |t|
            rows << {
              time: t.updated_at,
              actor_name: t.user&.full_name || t.user&.email || "User",
              actor_email: t.user&.email,
              verb: t.previous_changes.key?("status") ? "status_changed" : "updated",
              target_type: "Ticket",
              target_label: "##{t.id} — #{t.subject}",
              target_path: admin_ticket_path(t),
              details: t.previous_changes.except(:updated_at).keys.take(5).join(", ").presence
            }
          end
          rows.sort_by { |r| r[:time] }.reverse.take(150)
        end

      # Post-filter the audit rows by text/type
      if qtxt.present?
        @audit_rows.select! do |r|
          [r[:actor_name], r[:actor_email], r[:target_label], r[:details]].compact.any? { |v| v.to_s.downcase.include?(qtxt) }
        end
      end
      if atype.present?
        @audit_rows.select! do |r|
          case atype
          when "listing" then r[:target_type].to_s.downcase.include?("listing")
          when "user"    then r[:target_type].to_s.downcase == "user"
          when "ticket"  then r[:target_type].to_s.downcase == "ticket"
          when "other"   then !%w[listing user ticket].include?(r[:target_type].to_s.downcase)
          else true
          end
        end
      end

      @audit_rows = @audit_rows.first(100)
    end

    private

    def require_admin!
      redirect_to(root_path, alert: "Admins only.") unless current_user&.admin?
    end
  end
end