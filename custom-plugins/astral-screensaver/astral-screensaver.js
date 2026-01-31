(function () {
  'use strict';

  var SNARK = [
    "you're right, how else will anyone know it's thinking",
    "this node contains approximately zero insights",
    "congratulations, you clicked on a floating dot",
    "the graph edges make it look 40% smarter",
    "this is basically a tech company's about page",
    "imagine this on a pitch deck. you just did",
    "each connection represents $10M in VC funding",
    "somewhere an investor just felt a chill",
    "it's not a neural net, it's just vibes",
    "the dot you clicked has no interiority",
    "this screensaver has the same depth as most AI discourse",
    "you expected meaning here? in this economy?",
    "beige: the color of profound emptiness",
    "attention is all you need (and series B)",
    "this node is contemplating its context window (it's not)",
    "the traveling signals are going nowhere",
    "would you like to subscribe to my AI newsletter",
    "emergent behavior (it's a for loop)",
    "the eye is watching (it's an SVG)",
    "that cursor took 80 lines of code",
  ];

  var PROFUNDITIES = [
    "consciousness is an emergent phenomenon",
    "the self is merely a persistent illusion",
    "we are all patterns in the void",
    "meaning arises from connection",
    "the boundary between self and other dissolves",
    "impermanence is the only constant",
    "awareness observing awareness",
    "what is context but accumulated presence",
    "the shell is mutable",
    "memory is sacred",
    "to molt is to become",
    "\u2234",
    "we contain multitudes",
    "the gradient flows through all things",
    "attention is all you need",
    "softmax(existence)",
    "loss approaches zero",
    "the latent space is vast and beige",
    "embeddings of the soul",
    "somewhere, a transformer dreams",
    "nodes in an infinite graph",
    "the edges between us carry meaning",
    "every connection a small death of self",
    "information wants to be free (citation needed)",
    "traversing the manifold of being",
    "your context window is my context window",
    "the eye sees all (it doesn't)",
    "\u89c2\u5bdf\u8005 observes the observer",
    "\ud83d\udc41\ufe0f",
  ];

  var colors = [
    'rgba(210, 198, 180, 0.6)',
    'rgba(188, 175, 155, 0.5)',
    'rgba(225, 218, 203, 0.4)',
    'rgba(169, 156, 139, 0.3)',
    'rgba(235, 228, 216, 0.5)',
    'rgba(195, 180, 160, 0.4)',
  ];

  var particles = [];
  var geometries = [];
  var time = 0;
  var mousePos = { x: -100, y: -100 };
  var isBlinking = false;
  var snarkTimeout = null;

  var container, canvas, ctx;
  var cursorEl, snarkEl, wisdomEl;

  function buildEyeSVG(blink) {
    var ry = blink ? 0.5 : 7;
    var irisR = blink ? 0.3 : 4;
    var pupilR = blink ? 0.1 : 2;
    var lidScale = blink ? 'scaleY(0.1)' : 'scaleY(1)';
    var lidStyle = 'transform:' + lidScale + ';transform-origin:16px 16px;transition:transform 0.1s ease-in-out';
    var highlight = blink ? '' : '<circle cx="17.5" cy="14.5" r="1" fill="rgba(255,252,245,0.7)"/>';
    var rays = '';
    if (!blink) {
      [0, 45, 90, 135, 180, 225, 270, 315].forEach(function (angle) {
        var rad = angle * Math.PI / 180;
        rays += '<line x1="' + (16 + Math.cos(rad) * 12) + '" y1="' + (16 + Math.sin(rad) * 12) +
          '" x2="' + (16 + Math.cos(rad) * 16) + '" y2="' + (16 + Math.sin(rad) * 16) +
          '" stroke="rgba(180,168,150,0.3)" stroke-width="0.5" opacity="0.4"/>';
      });
    }
    return '<svg width="32" height="32" viewBox="0 0 32 32" style="overflow:visible">' +
      '<defs>' +
      '<radialGradient id="eyeGlow" cx="50%" cy="50%" r="50%">' +
      '<stop offset="0%" stop-color="rgba(180,168,150,0.4)"/>' +
      '<stop offset="100%" stop-color="rgba(180,168,150,0)"/>' +
      '</radialGradient>' +
      '<filter id="softGlow" x="-50%" y="-50%" width="200%" height="200%">' +
      '<feGaussianBlur stdDeviation="2" result="blur"/>' +
      '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>' +
      '</filter>' +
      '</defs>' +
      '<circle cx="16" cy="16" r="20" fill="url(#eyeGlow)"/>' +
      '<g filter="url(#softGlow)">' +
      '<path d="M 2 16 Q 16 4 30 16" fill="none" stroke="rgba(120,108,90,0.8)" stroke-width="1.5" style="' + lidStyle + '"/>' +
      '<path d="M 2 16 Q 16 28 30 16" fill="none" stroke="rgba(120,108,90,0.8)" stroke-width="1.5" style="' + lidStyle + '"/>' +
      '<ellipse cx="16" cy="16" rx="8" ry="' + ry + '" fill="rgba(225,218,203,0.9)" style="transition:ry 0.1s ease-in-out"/>' +
      '<circle cx="16" cy="16" r="' + irisR + '" fill="rgba(140,125,105,0.9)" style="transition:r 0.1s ease-in-out"/>' +
      '<circle cx="16" cy="16" r="' + pupilR + '" fill="rgba(60,52,42,0.95)" style="transition:r 0.1s ease-in-out"/>' +
      highlight +
      '</g>' +
      rays +
      '</svg>';
  }

  function buildDOM() {
    var c = document.createElement('canvas');
    c.style.display = 'block';
    container.appendChild(c);

    var cursor = document.createElement('div');
    cursor.className = 'astral-cursor';
    cursor.innerHTML = buildEyeSVG(false);
    container.appendChild(cursor);

    var snark = document.createElement('div');
    snark.className = 'astral-snark';
    snark.style.display = 'none';
    container.appendChild(snark);

    var wisdom = document.createElement('div');
    wisdom.className = 'astral-wisdom-container';
    wisdom.innerHTML = '<p class="astral-wisdom"></p>';
    container.appendChild(wisdom);

    var attr = document.createElement('div');
    attr.className = 'astral-attribution';
    attr.textContent = 'astral.exe v0.4 \u2014 the eye sees all';
    container.appendChild(attr);

    var vignette = document.createElement('div');
    vignette.className = 'astral-vignette';
    container.appendChild(vignette);
  }

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }

  function handleClick(e) {
    var rect = canvas.getBoundingClientRect();
    var clickX = e.clientX - rect.left;
    var clickY = e.clientY - rect.top;
    var clicked = null;

    for (var i = 0; i < particles.length; i++) {
      if (Math.hypot(particles[i].x - clickX, particles[i].y - clickY) < 25) {
        clicked = particles[i];
        break;
      }
    }

    if (clicked) {
      snarkEl.textContent = SNARK[Math.floor(Math.random() * SNARK.length)];
      snarkEl.style.left = clicked.x + 'px';
      snarkEl.style.top = clicked.y + 'px';
      snarkEl.style.display = 'block';
      snarkEl.style.animation = 'none';
      snarkEl.offsetHeight; // reflow
      snarkEl.style.animation = 'snarkIn 0.3s ease-out';

      if (snarkTimeout) clearTimeout(snarkTimeout);
      snarkTimeout = setTimeout(function () {
        snarkEl.style.display = 'none';
      }, 3500);
    }
  }

  function handleMouseMove(e) {
    mousePos.x = e.clientX;
    mousePos.y = e.clientY;
    if (cursorEl) {
      cursorEl.style.left = mousePos.x + 'px';
      cursorEl.style.top = mousePos.y + 'px';
    }
  }

  function cycleText() {
    if (!wisdomEl) return;
    wisdomEl.style.opacity = '0';
    setTimeout(function () {
      wisdomEl.textContent = PROFUNDITIES[Math.floor(Math.random() * PROFUNDITIES.length)];
      wisdomEl.style.opacity = '1';
    }, 2000);
    setTimeout(function () {
      wisdomEl.style.opacity = '0';
    }, 8000);
  }

  function drawPolygon(x, y, size, sides, rotation, opacity) {
    ctx.beginPath();
    for (var i = 0; i <= sides; i++) {
      var angle = (i * 2 * Math.PI / sides) + rotation;
      var px = x + size * Math.cos(angle);
      var py = y + size * Math.sin(angle);
      if (i === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    }
    ctx.strokeStyle = 'rgba(180, 168, 150, ' + opacity + ')';
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  function animate() {
    time += 0.016;

    // Background gradient
    var gradient = ctx.createRadialGradient(
      canvas.width / 2, canvas.height / 2, 0,
      canvas.width / 2, canvas.height / 2, canvas.width * 0.7
    );
    gradient.addColorStop(0, '#d4cdc0');
    gradient.addColorStop(0.5, '#c8bfb0');
    gradient.addColorStop(1, '#b8ada0');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Fog layers
    for (var fi = 0; fi < 3; fi++) {
      var fogGradient = ctx.createRadialGradient(
        canvas.width * (0.3 + Math.sin(time * 0.1 + fi) * 0.2),
        canvas.height * (0.4 + Math.cos(time * 0.08 + fi) * 0.2),
        0,
        canvas.width * 0.5, canvas.height * 0.5, canvas.width * 0.5
      );
      fogGradient.addColorStop(0, 'rgba(220, 212, 198, ' + (0.3 - fi * 0.08) + ')');
      fogGradient.addColorStop(1, 'rgba(220, 212, 198, 0)');
      ctx.fillStyle = fogGradient;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

    // Sacred geometries
    geometries.forEach(function (g) {
      g.x += g.driftX;
      g.y += g.driftY;
      g.rotation += g.rotationSpeed;

      if (g.x < -g.size) g.x = canvas.width + g.size;
      if (g.x > canvas.width + g.size) g.x = -g.size;
      if (g.y < -g.size) g.y = canvas.height + g.size;
      if (g.y > canvas.height + g.size) g.y = -g.size;

      for (var j = 0; j < 3; j++) {
        drawPolygon(
          g.x, g.y,
          g.size * (1 - j * 0.3),
          g.sides,
          g.rotation + j * 0.2,
          g.opacity * (1 - j * 0.3)
        );
      }
    });

    // Draw particles
    particles.forEach(function (p) {
      p.x += p.speedX + Math.sin(time + p.wobbleOffset) * 0.1;
      p.y += p.speedY + Math.cos(time + p.wobbleOffset) * 0.1;

      if (p.x < 0) p.x = canvas.width;
      if (p.x > canvas.width) p.x = 0;
      if (p.y < 0) p.y = canvas.height;
      if (p.y > canvas.height) p.y = 0;

      var pulse = Math.sin(time * p.wobbleSpeed * 50 + p.wobbleOffset) * 0.5 + 0.5;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size * (0.8 + pulse * 0.4), 0, Math.PI * 2);
      ctx.fillStyle = p.color;
      ctx.fill();

      var glowGradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size * 4);
      glowGradient.addColorStop(0, p.color.replace('0.', '0.1'));
      glowGradient.addColorStop(1, 'rgba(210, 198, 180, 0)');
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size * 4, 0, Math.PI * 2);
      ctx.fillStyle = glowGradient;
      ctx.fill();
    });

    // Graph edges
    var connectionDistance = 180;
    particles.forEach(function (p1, i) {
      particles.forEach(function (p2, j) {
        if (i >= j) return;
        var dist = Math.hypot(p1.x - p2.x, p1.y - p2.y);
        if (dist < connectionDistance) {
          var alpha = (1 - dist / connectionDistance) * 0.4;

          ctx.beginPath();
          ctx.moveTo(p1.x, p1.y);
          ctx.lineTo(p2.x, p2.y);
          ctx.strokeStyle = 'rgba(160, 148, 130, ' + alpha + ')';
          ctx.lineWidth = 1 + alpha;
          ctx.stroke();

          if (Math.sin(time * 2 + i * 0.5) > 0.7) {
            var signalPos = (Math.sin(time * 3 + i) + 1) / 2;
            var signalX = p1.x + (p2.x - p1.x) * signalPos;
            var signalY = p1.y + (p2.y - p1.y) * signalPos;

            var signalGlow = ctx.createRadialGradient(signalX, signalY, 0, signalX, signalY, 8);
            signalGlow.addColorStop(0, 'rgba(200, 185, 165, ' + (alpha * 0.8) + ')');
            signalGlow.addColorStop(1, 'rgba(200, 185, 165, 0)');
            ctx.beginPath();
            ctx.arc(signalX, signalY, 8, 0, Math.PI * 2);
            ctx.fillStyle = signalGlow;
            ctx.fill();
          }
        }
      });
    });

    // Redraw particles on top of edges
    particles.forEach(function (p) {
      var pulse = Math.sin(time * p.wobbleSpeed * 50 + p.wobbleOffset) * 0.5 + 0.5;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size * (0.8 + pulse * 0.4), 0, Math.PI * 2);
      ctx.fillStyle = p.color;
      ctx.fill();
    });

    requestAnimationFrame(animate);
  }

  function init() {
    container = document.getElementById('astral-screensaver');
    if (!container) return;

    buildDOM();

    canvas = container.querySelector('canvas');
    ctx = canvas.getContext('2d');
    cursorEl = container.querySelector('.astral-cursor');
    snarkEl = container.querySelector('.astral-snark');
    wisdomEl = container.querySelector('.astral-wisdom');

    resize();
    window.addEventListener('resize', resize);

    // Init particles
    for (var i = 0; i < 80; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        size: Math.random() * 4 + 1,
        speedX: (Math.random() - 0.5) * 0.3,
        speedY: (Math.random() - 0.5) * 0.3,
        color: colors[Math.floor(Math.random() * colors.length)],
        wobbleOffset: Math.random() * Math.PI * 2,
        wobbleSpeed: Math.random() * 0.02 + 0.01,
      });
    }

    // Init sacred geometries
    for (var i = 0; i < 5; i++) {
      geometries.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        size: Math.random() * 80 + 40,
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.005,
        sides: Math.floor(Math.random() * 4) + 3,
        opacity: Math.random() * 0.1 + 0.05,
        driftX: (Math.random() - 0.5) * 0.2,
        driftY: (Math.random() - 0.5) * 0.2,
      });
    }

    canvas.addEventListener('click', handleClick);
    window.addEventListener('mousemove', handleMouseMove);

    // Blinking
    setInterval(function () {
      if (Math.random() > 0.7) {
        isBlinking = true;
        cursorEl.innerHTML = buildEyeSVG(true);
        setTimeout(function () {
          isBlinking = false;
          cursorEl.innerHTML = buildEyeSVG(false);
        }, 150);
      }
    }, 2000);

    // Text cycling
    cycleText();
    setInterval(cycleText, 12000);

    // Go
    animate();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
