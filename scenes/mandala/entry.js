  {
    key: 'mandala', cont: ['orient', 'sb'], name: 'DALA62', src: R_MANDALA, cost: 1.6,
    auto: { tier: 2, kind: 'flat', kal: [6, 8, 0, 12, 16, 5], kalCycle: true, kalZoom: 0.7, bars: 32, transitions: ['kaleido', 'vortex'], fx: { warp: 0.4 },
      notes: 'v12 (v12/b0_kal, kal1, kz05): the rose-window cathedral folds into full medallion mandalas at every fold; in the dive a fold centres the set as a jewel star (better than the off-centre unfolded dive); 2/3/4 slice the dive blob; kalZoom .5 no fuller than .7' },
    fb: { zoom: -0.002, rot: 0.0015, decay: 0.7, warp: 0.15, echo: 0.28, droste: 0, win: 0.75, key: 0.2, live: 0.4 }, syms: [0, 0, 0, 6, 6, 5, 8, 12, 16, 4, 3], kalZoom: 0.7,
    init: (s) => {
      const motif = DALA_MOTIFS[Math.min(DALA_MOTIFS.length - 1, Math.floor(s[0] * DALA_MOTIFS.length))];
      const turn = Math.floor(s[3] * (motif[0] - 1)) * Math.PI * 2 / (motif[0] - 1);
      const co = Math.cos(turn), si = Math.sin(turn);
      return { pw: motif[0], targetPeriod: motif[1],
        anchor: [motif[3] * co - motif[4] * si, motif[3] * si + motif[4] * co],
        mirror: s[2] < .1, th: motif[2] + turn + (s[2] - .5) * .03,
        orient: s[0] * 6.283, sb: s[1], sd: [3, 4, 5, 6, 7][Math.floor(s[2] * 5)],
        ph: 0, T: 0, Z: 0, la: s[1] * 6.283, laT: s[1] * 6.283, bloom: 0,
        cyc: null, cc: null, out: 0, wrap: 0, bars: 0, glass: s[3] < .5, kAdd: 0, de0: .0018 + .0027 * ((s[1] * 7.31) % 1),
        periodBias: .2 + .2 * s[1],
        // cathedral: cells per ring (a multiple of the power), stagger, medallion orientation, ring spin pattern
        catM: (() => { const ms = []; for (let k = 1; k < 12; k++) if (motif[0] * k >= 9 && motif[0] * k <= 21) ms.push(motif[0] * k); return ms[Math.floor(((s[1] * 7.7 + s[2] * 3.1) % 1) * ms.length)]; })(),
        catS: [0, .5, .25, .5][Math.floor(((s[0] * 5.3 + s[3] * 2.9) % 1) * 4)], catPhi: Math.floor(s[1] * 4) * Math.PI / 2,
        rdE: 1, rdO: [-1, -1, -1, 1, 0][Math.floor(((s[2] * 9.1 + s[0] * 1.7) % 1) * 5)],
        catZ: [1, 1, .5, .3][Math.floor(((s[3] * 6.1 + s[1] * 3.3) % 1) * 4)],
        flow: 0, rotE: 0, rotO: 0, wd: 1, wide: 0, pb: 0 };
    },
    frame(V, F, dt) {
      dalaFrame(V, F, dt);
      // the drop's bloom-out should read as a clean burst, not a feedback smear
      const b = Math.min(1, V.c.bloom || 0);
      // the cathedral is crisp linework: it keeps the trails shorter still
      const w = 1 - 0.5 * Math.min(1, Math.max(0, 1 - V.c.wd) * 2);
      this.fb.warp = 0.15 * w * (1 - 0.8 * b); this.fb.echo = 0.28 * w * (1 - 0.7 * b);
      // the drop cuts to a new image: the old frame must not linger as a zoomed, glowing ghost behind it
      this.fb.decay = 0.7 * (1 - 0.8 * b);
    }
  },
