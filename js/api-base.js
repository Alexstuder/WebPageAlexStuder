(function(){
  const override = window.API_BASE_URL || (window.localStorage ? window.localStorage.getItem('API_BASE_URL') : null);
  const host = window.location.hostname;
  const protocol = window.location.protocol;
  const isLocalHost = host === 'localhost' || host === '127.0.0.1' || host === '' || host === '0.0.0.0';
  const defaultLocalBase = 'http://localhost:3000';
  const base = override
    || (protocol === 'file:' ? defaultLocalBase : null)
    || (isLocalHost ? defaultLocalBase : '');

  window.getApiUrl = function(path){
    if(!path) return base || '';
    const trimmed = path.startsWith('/') ? path : `/${path}`;
    if(!base){
      return trimmed;
    }
    return `${base}${trimmed}`;
  };
})();
