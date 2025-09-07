import { Controller } from "@hotwired/stimulus";

const TEMPLATE = `
<div id="modal-root" data-turbo-permanent>
  <div class="modal fade" id="confirmDeleteModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content border-0 rounded-4 shadow-lg">
        <div class="modal-header border-0">
          <h5 class="modal-title">Delete conversation?</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body"><p class="mb-0" id="confirmDeleteBody"></p></div>
        <div class="modal-footer border-0">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
          <a id="confirmDeleteBtn" class="btn btn-danger" data-turbo-method="delete">Delete</a>
        </div>
      </div>
    </div>
  </div>
</div>
`;

let installedTurboGuards = false;

export default class extends Controller {
  connect() {
    // Inject modal once
    if (!document.getElementById("confirmDeleteModal")) {
      const host = document.createElement("div");
      host.innerHTML = TEMPLATE;
      document.body.appendChild(host.firstElementChild);
    }

    // Global guard: if Turbo is about to render/visit, close any open modals.
    if (!installedTurboGuards) {
      const hideAllModals = () => {
        const el = document.getElementById("confirmDeleteModal");
        if (!el) return;
        const inst = bootstrap.Modal.getOrCreateInstance(el);
        inst.hide();
      };
      document.addEventListener("turbo:before-visit", hideAllModals);
      document.addEventListener("turbo:before-stream-render", hideAllModals);
      installedTurboGuards = true;
    }
  }

  open() {
    const url  = this.element.dataset.deleteUrl;
    const text =
      this.element.dataset.deleteText ||
      "This will permanently delete this conversation. This action can’t be undone.";

    const bodyEl = document.getElementById("confirmDeleteBody");
    const btnEl  = document.getElementById("confirmDeleteBtn");
    const modalEl = document.getElementById("confirmDeleteModal");
    const modal  = bootstrap.Modal.getOrCreateInstance(modalEl);

    bodyEl.textContent = text;
    btnEl.setAttribute("href", url);

    // IMPORTANT: close the modal immediately when the red Delete is clicked.
    // We do NOT call preventDefault, so the link still performs DELETE via Turbo.
    btnEl.onclick = () => { modal.hide(); };

    modal.show();
  }
}