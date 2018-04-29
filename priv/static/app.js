var app = new Vue({
  el: "#app",

  data() {
    return {
      greeting: "Hello from Vue!",
      requests: []
    };
  },

  created() {
    this.loadRequests();
  },

  methods: {
    // Load requests from backend
    loadRequests() {
      let self = this;
      
      axios.get("/requests")
        .then(function(resp) {
          self.requests = resp.data;
        });
    }
  }
});


let source = new EventSource("/sse");

source.addEventListener("message", function(event) {
  console.log(`Received event: ${event}`);

  // Make the Vue app reload the requests when there was an update
  if (event.data === "updated") {
    app.loadRequests();
  }
}, false);

source.addEventListener("open", function(event) {
  console.log("EventSource connected.");
}, false);

source.addEventListener("error", function(event) {
  if (event.eventPhase == EventSource.CLOSED) 
    console.log("EventSource was closed.");
}, false);