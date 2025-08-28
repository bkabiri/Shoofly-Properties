(function () {
    const billingToggle = document.getElementById('billingToggle');
    const prices = document.querySelectorAll('.price');
    const periods = document.querySelectorAll('.period');

    const slider = document.getElementById('usageSlider');
    const bubble = document.getElementById('bubble');
    const bubbleValue = document.getElementById('bubbleValue');
    const bubbleUnit = document.getElementById('bubbleUnit');

    const sellersTab = document.getElementById('sellers-tab');
    const agentsTab  = document.getElementById('agents-tab');

    function setBilling() {
      const yearly = billingToggle.checked;
      prices.forEach(p => p.textContent = yearly ? p.dataset.yearly : p.dataset.monthly);
      periods.forEach(el => el.textContent = yearly ? '/yr' : '/mo');
    }

    function setSliderUI() {
      const tabIsAgents = document.getElementById('agents').classList.contains('active');

      // Configure scale per tab
      if (tabIsAgents) {
        slider.min = 1; slider.max = 120; slider.step = 1;
        if (Number(slider.value) < 1) slider.value = 20;
        bubbleUnit.textContent = 'Listings';
      } else {
        slider.min = 1; slider.max = 2; slider.step = 1;
        if (Number(slider.value) > 2) slider.value = 1;
        bubbleUnit.textContent = 'Listing' + (slider.value === '1' ? '' : 's');
      }
      updateBubble();
      highlightPlan();
    }

    function updateBubble() {
      bubbleValue.textContent = slider.value;
      // position bubble (0..1)
      const val = (slider.value - slider.min) / (slider.max - slider.min || 1);
      const pct = val * 100;
      bubble.style.left = `calc(${pct}% )`;
      if (slider.max !== '2') bubbleUnit.textContent = 'Listings';
      if (document.getElementById('sellers').classList.contains('active')) {
        bubbleUnit.textContent = Number(slider.value) === 1 ? 'Listing' : 'Listings';
      }
    }

    function highlightPlan() {
      document.querySelectorAll('.plan-card').forEach(c => c.classList.remove('highlight'));
      const inAgents = document.getElementById('agents').classList.contains('active');
      const value = Number(slider.value);
      let key;
      if (inAgents) {
        key = value <= 20 ? 'agents-starter' : 'agents-unlimited';
      } else {
        key = value <= 1 ? 'sellers-basic' : 'sellers-plus';
      }
      const card = document.querySelector(`.plan-card[data-plan="${key}"]`);
      if (card) card.classList.add('highlight');
    }

    billingToggle.addEventListener('change', setBilling);
    slider.addEventListener('input', () => { updateBubble(); highlightPlan(); });

    sellersTab.addEventListener('shown.bs.tab', setSliderUI);
    agentsTab.addEventListener('shown.bs.tab', setSliderUI);

    // init
    setBilling();
    setSliderUI();
  })();