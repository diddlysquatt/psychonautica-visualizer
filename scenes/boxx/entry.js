  {
    key: 'boxx', name: 'BOXX 7', src: R_BOXX, cost: 1.6, cont: [], continuousJourney: true, motionLP: 1,
    description: 'an endless dive through boxes, and each box opens onto a truly different world: a castle at sunset, a neon city, a giant toadstool forest, a clockwork yard of meshing gears, a crystal valley under an aurora, a candy land, a moon base, a pagoda village, a desert of pyramids, the Rubik towers, a circuit-board megacity, a basalt field in lava, a coral reef, a library of giant books, sky islands above the clouds, and a snow forest; the bass swells every structure, the kick sends a hop and a ring of light, the mids fill the windows and lanterns, the highs light stars and rims, and pulled right out the camera arcs high over each world and still dives through the next door', kalZoom: 1,
    fb: { zoom: 0, rot: 0, decay: 0.08, warp: 0, echo: 0, droste: 0, win: 0, key: 0.1, live: 0.2 },
    syms: [0, 0, 0, 0, 0, 0, 4, 6, 8, 8, 12, 12, 16],
    auto: { kal: [0, 8, 12, 6, 16, 4], kalCycle: true, kalZoom: 1, transitions: ['portal', 'shatter'], kind: '3d', tier: 1, bars: 48,
      fx: { trails: 0.3, warp: 0.1, bloom: 0.7, chroma: 0.2 },
      notes: 'unfolded is the hero view (the dive through box doors and unfolding boxes into eleven kinds of box world, all playing the music); the special box sits on the fold centre, so 8/12/6/16 make mandalas of it with the city/gifts/stickers around; 4 is a square tunnel; 2 doubles the box, 3/5 cut it' },
    init: (s) => boxxInit(s),
    frame(V, F, dt) { boxxFrame(V, F, dt); }
  },
