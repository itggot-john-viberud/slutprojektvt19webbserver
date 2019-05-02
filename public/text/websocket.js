window.onload = function(){
    (function(){
      var show = function(el){
        return function(msg){
          let parsed = JSON.parse(msg)
          console.log(parsed.message)
          console.log(parsed.user)
          id = parsed.id
          newarray = '<form method="get" action="/edit/'+id+'"><button type="submit">Edit</button></form>' +'<form method="post" action="/delete/'+id+'"><button type="submit">Delete</button></form><br />' + parsed.user + '</br>' + '</br>' +  parsed.message + '</br>' + '</br>'; 
          el.innerHTML = el.innerHTML + newarray
      }


      
      }(document.getElementById('msgs'));

      var ws       = new WebSocket('ws://' + window.location.host + window.location.pathname);
      ws.onopen    = function()  { show('websocket opened'); };
      ws.onclose   = function()  { show('websocket closed'); }
      ws.onmessage = function(m) { show(m.data); };

      var sender = function(f){
        var input     = document.getElementById('input');
        input.onclick = function(){ input.value = "" };
        f.onsubmit    = function(){
          ws.send(input.value);
          input.value = "send a message";
          return false;
        }
      }(document.getElementById('form'));
    })();
  }