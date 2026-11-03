// Dependency-free SVG line chart for the dashboard trend.
function lineChart(el) {
  if (!el) return;
  const labels = JSON.parse(el.dataset.labels || "[]");
  const values = JSON.parse(el.dataset.values || "[]");
  const w = 640, h = 180, pad = 28;
  const max = Math.max(1, ...values);
  const x = i => pad + i * ((w - pad * 2) / Math.max(1, values.length - 1));
  const y = v => h - pad - (v / max) * (h - pad * 2);
  const pts = values.map((v, i) => `${x(i)},${y(v)}`).join(" ");
  let grid = "";
  for (let g = 0; g <= max; g += Math.max(1, Math.ceil(max / 4)))
    grid += `<line x1="${pad}" y1="${y(g)}" x2="${w - pad}" y2="${y(g)}" stroke="#262C31"/>
             <text x="2" y="${y(g) + 4}" fill="#8B929A" font-size="10">${g}</text>`;
  el.innerHTML = `<svg viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
    ${grid}
    <polyline points="${pts}" fill="none" stroke="#F0A232" stroke-width="2"/>
    ${values.map((v, i) => `<circle cx="${x(i)}" cy="${y(v)}" r="3" fill="#F0A232"><title>${labels[i]}: ${v}</title></circle>`).join("")}
  </svg>`;
}
