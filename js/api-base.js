(function(){
  const STORAGE_KEY = 'API_BASE_URL';
  const defaultLocalBase = 'http://localhost:3000';
  const host = window.location.hostname;
  const protocol = window.location.protocol;
  const isLocalHost =
    host === 'localhost' ||
    host === '127.0.0.1' ||
    host === '' ||
    host === '0.0.0.0' ||
    host.endsWith('.local');
  const rawOverride = window.API_BASE_URL || (window.localStorage ? window.localStorage.getItem(STORAGE_KEY) : null);
  const isProbablyProd = !isLocalHost && protocol !== 'file:' && host !== '';
  const isLocalOverride = value => {
    if(!value) return false;
    try{
      const parsed = new URL(value, window.location.origin);
      const overrideHost = parsed.hostname;
      return (
        overrideHost === 'localhost' ||
        overrideHost === '127.0.0.1' ||
        overrideHost === '0.0.0.0' ||
        overrideHost.endsWith('.local')
      );
    }catch(error){
      return false;
    }
  };

  const canUseOverride = rawOverride && (!isProbablyProd || !isLocalOverride(rawOverride));
  if(rawOverride && !canUseOverride && window.localStorage){
    window.localStorage.removeItem(STORAGE_KEY);
  }

  const base = canUseOverride
    ? rawOverride
    : (protocol === 'file:' || isLocalHost ? defaultLocalBase : '');

  window.getApiUrl = function(path){
    if(!path) return base || '';
    const trimmed = path.startsWith('/') ? path : `/${path}`;
    if(!base){
      return trimmed;
    }
    return `${base}${trimmed}`;
  };
})();
