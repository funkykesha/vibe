import { logger } from './logger.mjs';

export class Scheduler {
  constructor({ intervalMin = 30, modemIface, sampleAll, appendRecord }) {
    this.intervalMin = Math.max(0, intervalMin | 0);
    this.modemIface = modemIface;
    this.sampleAll = sampleAll;
    this.appendRecord = appendRecord;
    this.sampling = false;
    this.timer = null;
    this.lastSampleTs = null;
  }

  state() {
    return {
      interval_min: this.intervalMin,
      last_sample_ts: this.lastSampleTs,
      sampling: this.sampling,
    };
  }

  start() {
    this._resetTimer();
  }

  stop() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  trigger() {
    if (this.sampling) return { started: false };
    this._runOnce();
    return { started: true };
  }

  setIntervalMin(n) {
    this.intervalMin = Math.max(0, n | 0);
    this._resetTimer();
    return this.intervalMin;
  }

  _resetTimer() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    if (this.intervalMin <= 0) return;
    if (this.sampling) return;
    this.timer = setTimeout(() => {
      this.timer = null;
      this._runOnce();
    }, this.intervalMin * 60 * 1000);
  }

  _runOnce() {
    if (this.sampling) return;
    this.sampling = true;
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    (async () => {
      try {
        await this.sampleAll({ modemIface: this.modemIface, appendRecord: this.appendRecord });
      } catch (e) {
        logger.error('sample failed:', e.stack || e.message);
      } finally {
        this.sampling = false;
        this.lastSampleTs = Date.now() / 1000;
        this._resetTimer();
      }
    })();
  }
}
