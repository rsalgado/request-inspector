function getKeyFromPath() { return window.location.pathname.split("/")[1]; }
function getAbsolutePath() { return window.location.href; }

let indexSection = Vue.component("index-section", {
  template: "#index-section",

  data() {
    return {
      greeting: "Hello from the index section!",
      endpointKey: ""
    };
  },

  methods: {
    getEndpointKey() {
      let self = this;
      axios.post("/keys")
        .then(response => self.endpointKey = response.data.key);
    }
  },

  computed: {
    hasEndpointKey() {  return this.endpointKey !== ""; }
  }
});

let requestsSection = Vue.component("requests-section", {
  template: "#requests-section",
  created() {
    this.loadRequests();
    this.startSSE();
  },

  updated() {
    this.$el.querySelectorAll("pre > code").forEach(block => {
      hljs.highlightBlock(block);
    });
  },

  data() {
    return {
      requests: [],
      key: getKeyFromPath(),
      endpointPath: `${getAbsolutePath()}/endpoint`
    };
  },

  computed: {
    numRequests() {
      return this.requests.length;
    }
  },

  methods: {
    // SSE client functionality (wrapped for convenience to avoid namespace issues)
    startSSE() {
      let source = new EventSource(`/${this.key}/sse`);
      let self = this;

      source.addEventListener("message", function(event) {
        console.log(`Received event: ${event}`);

        // Make the Vue app reload the requests when there was an update
        if (event.data === "updated") {
          self.loadRequests();
        }
      }, false);

      source.addEventListener("open", function(event) {
        console.log("EventSource connected.");
      }, false);

      source.addEventListener("error", function(event) {
        if (event.eventPhase == EventSource.CLOSED) 
          console.log("EventSource was closed.");
      }, false);
    },

    // Load requests from backend
    loadRequests() {
      let self = this;
      axios.get(`/${this.key}/requests`)
        .then(resp => self.requests = resp.data);
    },

    deleteEndpoint() {
      let confirmed = confirm("Are you sure you want to delete this endpoint?");
      if (confirmed) {
        axios.delete(`/${this.key}`)
          .then(_resp => window.location.href = "/")
      }
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

let app = new Vue({
  el: "#app",
  data() {
    return {
      isRootPage: getKeyFromPath() === ""
    }
  }
});
