var app = new Vue({
  el: "#app",

  data() {
    return {
      greeting: "Hello from Vue!",
      requests: []
    };
  },

  created() {
    let self = this;

    axios.get("/requests")
      .then(function(resp) {
        self.requests = resp.data;
      });
  }
});


let source = new EventSource("/sse");

source.addEventListener("message", function(event) {
  console.log(`Received event: ${event.data}`);
}, false);

source.addEventListener("open", function(event) {
  console.log("EventSource connected.");
}, false);

source.addEventListener("error", function(event) {
  if (event.eventPhase == EventSource.CLOSED) 
    console.log("EventSource was closed.");
}, false);