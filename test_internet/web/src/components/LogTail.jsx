import React, { useEffect, useRef } from 'react';

export function LogTail({ text, onRefresh }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current) ref.current.scrollTop = ref.current.scrollHeight;
  }, [text]);
  return (
    <div className="card">
      <div className="section-title">
        <h2>Logs</h2>
        <button type="button" className="secondary" onClick={onRefresh}>
          Refresh
        </button>
      </div>
      <pre className="logs" ref={ref}>
        {text || '(пусто)'}
      </pre>
    </div>
  );
}
