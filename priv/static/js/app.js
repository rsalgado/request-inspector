function getKeyFromPath() {
  return window.location.pathname.split("/")[1];
}

// SSE client functionality (wrapped for convenience to avoid namespace issues)
function startSSE() {
  let key = getKeyFromPath();
  let source = new EventSource(`/${key}/sse`);

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
};


let app = new Vue({
  el: "#app",

  created() {
    this.loadRequests();
    startSSE();
  },

  updated() {
    this.$el.querySelectorAll("pre > code").forEach(block => {
      hljs.highlightBlock(block);
    });
  },

  data() {
    return {
      requests: []
    };
  },

  computed: {
    numRequests() {
      return this.requests.length;
    }
  },

  methods: {
    // Load requests from backend
    loadRequests() {
      let self = this;
      let key = getKeyFromPath();

      axios.get(`/${key}/requests`)
        .then(function(resp) {
          self.requests = resp.data;
        });
    },

    isJSON(request) {
      let contentType = request.headers["content-type"] || "";
      return contentType === "application/json";
    },

    isForm(request) {
      let contentType = request.headers["content-type"] || "";
      return contentType === "application/x-www-form-urlencoded";
    },

    isText(request) {
      let textSubtypes = ["plain", "json", "xml", "html", "css", "javascript"];
      let contentType = request.headers["content-type"] || "";
      return contentType.startsWith("text/") || textSubtypes.some(sub => contentType.endsWith(sub));
    },

    getTextType(request) {
      let contentType = request.headers["content-type"];
      let textType = contentType.split("/")[1];
      
      if (textType === "*") return "plain";
      else  return textType;
    }
  }
});