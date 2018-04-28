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
    
    axios.get("/inspect")
      .then(function(resp) {
        self.requests = resp.data;
      });
  }
});