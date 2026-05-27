import React, { useMemo } from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  LineElement,
  PointElement,
  LinearScale,
  TimeScale,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';
import 'chartjs-adapter-date-fns';

ChartJS.register(LineElement, PointElement, LinearScale, TimeScale, Tooltip, Legend, Filler);

const COLOR = {
  download: '#6c8cff',
  upload: '#4fd1c5',
  ping: '#ffb454',
};

export function SpeedChart({ points, title }) {
  const data = useMemo(() => {
    const xy = (key) => points.map((p) => ({ x: p.ts * 1000, y: p[key] }));
    return {
      datasets: [
        {
          label: 'download (Mbps)',
          data: xy('download_mbps'),
          borderColor: COLOR.download,
          backgroundColor: COLOR.download + '22',
          tension: 0.25,
          spanGaps: true,
          yAxisID: 'mbps',
        },
        {
          label: 'upload (Mbps)',
          data: xy('upload_mbps'),
          borderColor: COLOR.upload,
          backgroundColor: COLOR.upload + '22',
          tension: 0.25,
          spanGaps: true,
          yAxisID: 'mbps',
        },
        {
          label: 'ping (ms)',
          data: xy('ping_ms'),
          borderColor: COLOR.ping,
          backgroundColor: COLOR.ping + '22',
          tension: 0.25,
          spanGaps: true,
          yAxisID: 'ms',
          borderDash: [4, 4],
        },
      ],
    };
  }, [points]);

  const options = useMemo(
    () => ({
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      scales: {
        x: {
          type: 'time',
          time: { tooltipFormat: 'yyyy-MM-dd HH:mm' },
          ticks: { color: '#7a8295' },
          grid: { color: '#2a3145' },
        },
        mbps: {
          type: 'linear',
          position: 'left',
          ticks: { color: '#7a8295' },
          grid: { color: '#2a3145' },
          beginAtZero: true,
          title: { display: true, text: 'Mbps', color: '#7a8295' },
        },
        ms: {
          type: 'linear',
          position: 'right',
          ticks: { color: '#7a8295' },
          grid: { drawOnChartArea: false },
          beginAtZero: true,
          title: { display: true, text: 'ms', color: '#7a8295' },
        },
      },
      plugins: {
        legend: { labels: { color: '#d8dde6' } },
        tooltip: {
          backgroundColor: '#1c2030',
          borderColor: '#3a5ce6',
          borderWidth: 1,
        },
      },
    }),
    []
  );

  return (
    <div className="card chart-card">
      <h2>{title}</h2>
      <div className="chart-wrap">
        {points.length === 0 ? (
          <div className="empty-state">Нет данных</div>
        ) : (
          <Line data={data} options={options} />
        )}
      </div>
    </div>
  );
}
