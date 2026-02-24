;(function () {
  function initDiagram(el) {
    if (el.hasAttribute('data-mdex-init')) return
    el.setAttribute('data-mdex-init', 'true')

    var state = {
      scale: 1,
      panX: 0,
      panY: 0,
      dragging: false,
      startX: 0,
      startY: 0,
    }
    var inner = el.querySelector('svg') || el.querySelector('img')
    if (!inner) return

    function apply() {
      inner.style.transform =
        'translate(' +
        state.panX +
        'px,' +
        state.panY +
        'px) scale(' +
        state.scale +
        ')'
      inner.style.transformOrigin = '0 0'
    }

    el.addEventListener(
      'wheel',
      function (e) {
        e.preventDefault()
        var rect = el.getBoundingClientRect()
        var mx = e.clientX - rect.left
        var my = e.clientY - rect.top
        var delta = e.deltaY > 0 ? 0.9 : 1.1
        var ns = Math.min(Math.max(state.scale * delta, 0.1), 10)
        var factor = ns / state.scale
        state.panX = mx - factor * (mx - state.panX)
        state.panY = my - factor * (my - state.panY)
        state.scale = ns
        apply()
      },
      { passive: false },
    )

    el.addEventListener('pointerdown', function (e) {
      if (e.button !== 0) return
      if (e.target.closest('.mdex-mermex-toolbar')) return
      state.dragging = true
      state.startX = e.clientX - state.panX
      state.startY = e.clientY - state.panY
      el.setPointerCapture(e.pointerId)
    })

    el.addEventListener('pointermove', function (e) {
      if (!state.dragging) return
      state.panX = e.clientX - state.startX
      state.panY = e.clientY - state.startY
      apply()
    })

    el.addEventListener('pointerup', function () {
      state.dragging = false
    })

    el.addEventListener('dblclick', function (e) {
      if (e.target.closest('.mdex-mermex-toolbar')) return
      state.scale = 1
      state.panX = 0
      state.panY = 0
      apply()
    })

    var zoomIn = el.querySelector('.mdex-mermex-zoom-in')
    var zoomOut = el.querySelector('.mdex-mermex-zoom-out')
    var reset = el.querySelector('.mdex-mermex-reset')
    var fs = el.querySelector('.mdex-mermex-fullscreen')

    if (zoomIn)
      zoomIn.addEventListener('click', function (e) {
        e.stopPropagation()
        state.scale = Math.min(state.scale * 1.2, 10)
        apply()
      })

    if (zoomOut)
      zoomOut.addEventListener('click', function (e) {
        e.stopPropagation()
        state.scale = Math.max(state.scale / 1.2, 0.1)
        apply()
      })

    if (reset)
      reset.addEventListener('click', function (e) {
        e.stopPropagation()
        state.scale = 1
        state.panX = 0
        state.panY = 0
        apply()
      })

    if (fs)
      fs.addEventListener('click', function (e) {
        e.stopPropagation()
        if (document.fullscreenElement === el) {
          document.exitFullscreen()
        } else {
          el.requestFullscreen()
        }
      })
  }

  function initAll() {
    document
      .querySelectorAll('.mdex-mermex:not([data-mdex-init])')
      .forEach(initDiagram)
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAll)
  } else {
    initAll()
  }

  new MutationObserver(function (mutations) {
    for (var i = 0; i < mutations.length; i++) {
      for (var j = 0; j < mutations[i].addedNodes.length; j++) {
        var node = mutations[i].addedNodes[j]
        if (node.nodeType !== 1) continue
        if (node.matches && node.matches('.mdex-mermex')) initDiagram(node)
        if (node.querySelectorAll) {
          node
            .querySelectorAll('.mdex-mermex:not([data-mdex-init])')
            .forEach(initDiagram)
        }
      }
    }
  }).observe(document.body, { childList: true, subtree: true })
})()
