import evaluateProbe from '../rpc/evaluateProbe';
import ModalEnv from './ModalEnv';

const runInvisibleProbe = (env: ModalEnv, locator: NodeLocator, attr: AstAttrWithValue) => {
  const id = `invisible-probe-${Math.floor(Number.MAX_SAFE_INTEGER * Math.random())}`;
  const localErrors: ProbeMarker[] = [];
  env.probeMarkers[id] = localErrors;

  let state: 'loading' | 'idle' = 'idle';
  let reloadOnDone = false;
  const onRpcDone = () => {
    state = 'idle';
    if (reloadOnDone) {
      reloadOnDone = false;
      performRpc();
    }
  }
  const performRpc = () => {
    state = 'loading';
    evaluateProbe(env, env.wrapTextRpc({ query: { attr, locator } }))
      .then((res) => {
        if (res.job !== undefined) {
          throw new Error(`Got concurrent response for non-concurrent request`);
        }
        const prevLen = localErrors.length;
        localErrors.length = 0;
        res.errors.forEach(({severity, start: errStart, end: errEnd, msg }) => {
          localErrors.push({ severity, errStart, errEnd, msg });
        })
        if (prevLen !== 0 || localErrors.length !== 0) {
          env.updateMarkers();
        }
        onRpcDone();
      })
      .catch((err) => {
        console.warn('Failed refreshing invisible probe', err);
        onRpcDone();
      });
  };

  const refresh = () => {
    if (state === 'loading') {
      reloadOnDone = true;
    } else {
      performRpc();
    }
  };
  env.onChangeListeners[id] = refresh;
  refresh();
};

export default runInvisibleProbe;
