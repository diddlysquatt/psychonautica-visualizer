/* ---- LED 06 helpers: Lorentz-matrix flight through a hyperbolic {p,q,r} honeycomb (hyperboloid model).
   Matrices are 4x4 row-major arrays; the 4th coordinate is time-like. Camera space -> world = L. */
const LED6 = {
  mul(A, B) { const C = new Array(16).fill(0); for (let i = 0; i < 4; i++) for (let k = 0; k < 4; k++) { const a = A[i * 4 + k]; if (a) for (let j = 0; j < 4; j++) C[i * 4 + j] += a * B[k * 4 + j]; } return C; },
  id() { return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]; },
  apply(L, X) { return [0, 1, 2, 3].map((i) => L[i * 4] * X[0] + L[i * 4 + 1] * X[1] + L[i * 4 + 2] * X[2] + L[i * 4 + 3] * X[3]); },
  inv(L) { const s = [1, 1, 1, -1], M = new Array(16); for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) M[i * 4 + j] = s[i] * L[j * 4 + i] * s[j]; return M; },
  toHyp(x) { const r2 = x[0] * x[0] + x[1] * x[1] + x[2] * x[2], k = 1 / (1 - r2); return [2 * x[0] * k, 2 * x[1] * k, 2 * x[2] * k, (1 + r2) * k]; },
  toBall(X) { const k = 1 / (1 + X[3]); return [X[0] * k, X[1] * k, X[2] * k]; },
  boost(u, s) {
    const ch = Math.cosh(s), sh = Math.sinh(s), B = LED6.id();
    for (let i = 0; i < 3; i++) { for (let j = 0; j < 3; j++) B[i * 4 + j] += (ch - 1) * u[i] * u[j]; B[i * 4 + 3] = sh * u[i]; B[12 + i] = sh * u[i]; }
    B[15] = ch; return B;
  },
  rot(ax, a) {
    const l = Math.hypot(ax[0], ax[1], ax[2]) || 1, x = ax[0] / l, y = ax[1] / l, z = ax[2] / l, c = Math.cos(a), s = Math.sin(a), t = 1 - c;
    return [t * x * x + c, t * x * y - s * z, t * x * z + s * y, 0, t * x * y + s * z, t * y * y + c, t * y * z - s * x, 0, t * x * z - s * y, t * y * z + s * x, t * z * z + c, 0, 0, 0, 0, 1];
  },
  planeRef(n) { const M = LED6.id(); for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) M[i * 4 + j] -= 2 * n[i] * n[j]; return M; },
  sphereRef(C, rho) {
    const N = [C[0] / rho, C[1] / rho, C[2] / rho, 1 / rho], eN = [N[0], N[1], N[2], -N[3]], M = LED6.id();
    for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) M[i * 4 + j] -= 2 * N[i] * eN[j];
    return M;
  },
  // Lorentz Gram-Schmidt on the columns, so accumulated rounding never drifts the camera off the hyperboloid
  orth(L) {
    const col = (j) => [L[j], L[4 + j], L[8 + j], L[12 + j]], ip = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2] - a[3] * b[3];
    const c3 = col(3); let n = Math.sqrt(Math.max(-ip(c3, c3), 1e-12)); c3.forEach((v, i) => (c3[i] = v / n));
    const out = [];
    for (let j = 0; j < 3; j++) {
      const c = col(j); let d = ip(c, c3); for (let i = 0; i < 4; i++) c[i] += d * c3[i];
      for (const o of out) { d = ip(c, o); for (let i = 0; i < 4; i++) c[i] -= d * o[i]; }
      n = Math.sqrt(Math.max(ip(c, c), 1e-12)); for (let i = 0; i < 4; i++) c[i] /= n;
      out.push(c);
    }
    out.push(c3);
    const M = new Array(16); for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) M[i * 4 + j] = out[j][i];
    return M;
  },
  // Coxeter mirrors of {p,q,r}: three planes through the cell centre and one sphere (the cell's face)
  cons(p, q, r) {
    const cp = Math.cos(Math.PI / p), cq = Math.cos(Math.PI / q), A = [1, 0, 0], Cn = [0, 0, 1], B = [-cp, Math.sqrt(Math.max(1 - cp * cp - cq * cq, 1e-5)), -cq];
    let F = v3.norm(v3.cross(A, B)); if (v3.dot(F, Cn) > 0) F = v3.sc(F, -1);
    const k = Math.abs(v3.dot(F, Cn)), cr = Math.cos(Math.PI / r), D = cr / Math.sqrt(Math.max(cr * cr - k * k, 1e-6)), rho = Math.sqrt(D * D - 1);
    const S = v3.sc(F, D), P2 = D - rho, dCell = 4 * Math.atanh(P2);
    const R = [LED6.planeRef(A), LED6.planeRef(B), LED6.planeRef(Cn), LED6.sphereRef(S, rho)];
    // the centres of the neighbouring cells: the cell centre reflected through each face
    const faces = [F], stack = [F];
    while (stack.length) {
      const f = stack.pop();
      for (const n of [A, B, Cn]) {
        const g = v3.add(f, v3.sc(n, -2 * v3.dot(f, n)));
        if (!faces.some((h) => v3.dot(h, g) > 0.999)) { faces.push(g); stack.push(g); }
      }
    }
    const rb = Math.tanh(dCell / 2), nbr = faces.map((f) => LED6.toHyp(v3.sc(f, rb)));
    return { A, B, Cn, S, rho, R, dCell, nbr, faces, D, P2 };
  },
  // v18: the flight is a rail that threads the open cells. A segment crosses one cell from the centre of the face it came in
  // by to the centre of the face it leaves by: in the ball a quadratic Bezier with its control point at the cell centre, so
  // both ends leave along the face's axis and the next cell continues with the same tangent. Face centres are the
  // points farthest from the LED tubes and bulbs. T = the isometry taking the segment's cell to the world.
  railMk(H, T, fin, dr) {
    let best = null, bs = -1e9;
    for (const f of H.faces) { const co = -v3.dot(fin, f); if (co < -0.2 || v3.dot(fin, f) > 0.999) continue; const sc = 0.7 * co + dr(); if (sc > bs) { bs = sc; best = f; } }
    return { T, fin, fout: best };
  },
  railNext(H, s, dr) { return LED6.railMk(H, LED6.orth(LED6.mul(s.T, LED6.sphereRef(v3.sc(s.fout, H.D), H.rho))), s.fout, dr); },
  railB(H, s, u) { const a = H.P2, i = 1 - u; return v3.add(v3.sc(s.fin, a * i * i), v3.sc(s.fout, a * u * u)); },
  railV(H, s, u) { const a = H.P2, d = v3.add(v3.sc(s.fin, -2 * a * (1 - u)), v3.sc(s.fout, 2 * a * u)), b = LED6.railB(H, s, u); return 2 * Math.max(Math.hypot(d[0], d[1], d[2]), 1e-3) / Math.max(1 - v3.dot(b, b), 1e-3); },
  railAdv(H, c, ds, dr) {
    const R = c.rail;
    for (let i = 0; i < 400 && ds > 1e-6; i++) {
      const s = R.q[0], v = LED6.railV(H, s, R.u), du = Math.min(ds / v, 0.04);
      R.u += du; ds -= du * v;
      if (R.u >= 1) { R.u -= 1; R.q.shift(); if (!R.q.length) R.q.push(LED6.railNext(H, s, dr)); }
      if (R.q.length < 2) R.q.push(LED6.railNext(H, R.q[0], dr));
    }
  },
  // world point a hyperbolic distance dist ahead of the camera's place on the rail
  railAt(H, c, dist, dr) {
    const R = c.rail; let j = 0, u = R.u, rem = dist;
    for (let i = 0; i < 800 && rem > 1e-5; i++) {
      const v = LED6.railV(H, R.q[j], u), du = Math.min(rem / v, 0.05);
      u += du; rem -= du * v;
      if (u >= 1) { u = 0; j++; if (j >= R.q.length) R.q.push(LED6.railNext(H, R.q[j - 1], dr)); }
    }
    return LED6.apply(R.q[j].T, LED6.toHyp(LED6.railB(H, R.q[j], u)));
  },
  // Exact symmetry g of the honeycomb that brings ball point x back into the central cell's chamber
  renorm(H, x) {
    let G = null, odd = 0, X = x.slice();
    for (let it = 0; it < 80; it++) {
      let done = true;
      for (let m = 0; m < 3; m++) {
        const n = [H.A, H.B, H.Cn][m], d = v3.dot(X, n);
        if (d > 1e-9) { X = v3.add(X, v3.sc(n, -2 * d)); G = G ? LED6.mul(H.R[m], G) : H.R[m]; odd ^= 1; done = false; }
      }
      const v = v3.add(X, v3.sc(H.S, -1)), l2 = v3.dot(v, v);
      if (l2 < H.rho * H.rho - 1e-9) { X = v3.add(H.S, v3.sc(v, H.rho * H.rho / Math.max(l2, 1e-18))); G = G ? LED6.mul(H.R[3], G) : H.R[3]; odd ^= 1; done = false; }
      if (done) break;
    }
    if (G && odd) G = LED6.mul(H.R[0], G); // keep it orientation-preserving
    return G;
  }
};
// v12: the visit's honeycomb (and its membranes' sub-tiling) can change mid-visit (a reboot set piece)
const LED6_HCS = [[4, 3, 5], [5, 3, 4], [5, 3, 5], [3, 5, 3], [4, 3, 6], [5, 3, 6], [3, 3, 6], [3, 4, 4]];
const LED6_PROGS = 6;   // LED programs: 0 classic, 1 equaliser, 2 ripple, 3 colour chase, 4 ticker, 5 sparkle
function latticeSetHC(c, i, u) {
  const HC = LED6_HCS[((i % 8) + 8) % 8], subs = { 3: [[6, 4], [3, 7], [9, 3]], 4: [[8, 3], [4, 5], [4, 6]], 5: [[10, 3], [5, 4]] }[HC[0]];
  c.HC = HC; c.ps = subs[Math.min(subs.length - 1, Math.floor(u * subs.length))]; c.H = LED6.cons(HC[0], HC[1], HC[2]); c.rail = null;
}
// Zoomed-out lens (uZoom < 1): blend s (0 at zoom 1, 1 at the widest zoom), lens blend b (0 rectilinear .. 1
// stereographic) and focal length F, so the horizontal half-angle runs from the default to 72 degrees. The shader
// only uses them below zoom 1; the kick's small focal pulse is left out of this wide view.
// v13: [lens zoom, camera distance behind the ball's centre, 0]. The lens zoom is the kaleidoscope pull-back times the
// wheel's zoom-in (a plain rectilinear lens); the wheel's zoom-out instead backs the camera out of the ball (0 at zoom 1
// and in, about 1 (the rim) near zoom .45, 1.75 at .15, where the whole orb hangs in a sky of smaller ones)
function latticeLens(V, fov) {
  const uz = typeof PTR !== 'undefined' && PTR.zoom > 0 ? PTR.zoom : 1;
  const z = Math.max(0.05, Math.max(uz, 1) * (V.kz ?? 1));
  // v20b: zoom-out never leaves the ball. It widens the lens instead (to .6 at zoom .15, about 175 degrees through the shader's fisheye) and returns the amount (0..1)
  const uo = Math.min(1, Math.max(0, -Math.log(uz) / Math.log(1 / 0.15)));
  return [z * (1 - 0.3 * uo), uo, 0];
}
