// CORS fix for Flutter web development
(function() {
  console.log('Aplicando correções CORS...');
  
  // Override XMLHttpRequest
  var originalOpen = XMLHttpRequest.prototype.open;
  var originalSend = XMLHttpRequest.prototype.send;
  var originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
  
  XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
    this._url = url;
    this._method = method;
    console.log('XHR Open:', method, url);
    
    if (url.includes('localhost:8000')) {
      this.withCredentials = false;
    }
    
    return originalOpen.apply(this, arguments);
  };
  
  XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
    console.log('Setting header:', header, value);
    
    // Evitar headers que podem causar preflight desnecessário
    if (this._url && this._url.includes('localhost:8000')) {
      var problematicHeaders = [
        'access-control-allow-origin',
        'access-control-allow-methods',
        'access-control-allow-headers'
      ];
      
      if (problematicHeaders.includes(header.toLowerCase())) {
        console.log('Bloqueando header problemático:', header);
        return;
      }
    }
    
    return originalSetRequestHeader.apply(this, arguments);
  };
  
  XMLHttpRequest.prototype.send = function(data) {
    console.log('XHR Send:', this._method, this._url, data);
    return originalSend.apply(this, arguments);
  };
  
  // Override fetch também
  if (window.fetch) {
    var originalFetch = window.fetch;
    window.fetch = function(url, options = {}) {
      console.log('Fetch:', url, options);
      
      if (typeof url === 'string' && url.includes('localhost:8000')) {
        options.mode = 'cors';
        options.credentials = 'omit';
        
        // Remove headers problemáticos
        if (options.headers) {
          var cleanHeaders = {};
          for (var key in options.headers) {
            if (!key.toLowerCase().startsWith('access-control-')) {
              cleanHeaders[key] = options.headers[key];
            }
          }
          options.headers = cleanHeaders;
        }
      }
      
      return originalFetch(url, options);
    };
  }
  
  console.log('Correções CORS aplicadas com sucesso!');
})();