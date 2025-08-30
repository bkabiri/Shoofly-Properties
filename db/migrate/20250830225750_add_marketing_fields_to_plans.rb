class AddMarketingFieldsToPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :plans, :short_description, :string
    add_column :plans, :features, :jsonb
    add_column :plans, :image_asset, :string
    add_column :plans, :submit_note, :string
  end
end
