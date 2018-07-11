function getKeyFromPath() { return window.location.pathname.match(/\/buckets\/(\w+)/i)[1]; }
function getAbsolutePath() { return window.location.href; }

let indexSection = Vue.component("index-section", {
  template: "#index-section",

  data() {
    return {
      endpointKey: ""
    };
  },

  methods: {
    getEndpointKey() {
      let self = this;
      axios.post("/buckets")
        .then(response => self.endpointKey = response.data.key);
    }
  },

  computed: {
    hasEndpointKey() {  return this.endpointKey !== ""; },
    bucketPath() { return `/buckets/${this.endpointKey}`; }
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
      let source = new EventSource(`/buckets/${this.key}/sse`);
      let self = this;

      source.addEventListener("message", (event) => {
        console.log(`Received event: ${event}`);

        // Make the Vue app reload the requests when there was an update
        if (event.data === "updated")   self.loadRequests();
      }, false);

      source.addEventListener("open", (event) => {
        console.log("EventSource connected.");
      }, false);

      source.addEventListener("error", (event) => {
        if (event.eventPhase == EventSource.CLOSED) {
          console.log("Reconnecting because EventSource was closed with event: ");
          console.log(event);
        }
      }, false);
    },

    // Load requests from backend
    loadRequests() {
      let self = this;
      axios.get(`/buckets/${this.key}/requests`)
        .then(resp => self.requests = resp.data);
    },

    deleteBucket() {
      let confirmed = confirm("Are you sure you want to delete this bucket?");
      if (confirmed) {
        axios.delete(`/buckets/${this.key}`)
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
  methods: {
    isRootPage() { return window.location.pathname === "/"; }
  }
});
