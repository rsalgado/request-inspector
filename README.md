# Request Inspector

A basic application for inspecting HTTP requests. I made this project for practice and learning
purposes, with the aim of getting a little more experience with Elixir. 
Make requests to `/endpoint` to both get the request's info as a JSON response and have the request
info stored in a list you can see in the front-end at `/`. If you keep it (the front-end) open, it **updates
automatically** when new requests are made.


It uses the following technologies:

* **Plug**: as the server, with a router with a few routes, and a custom plug parser for text content.
* **Poison**: for encoding/decoding between JSON and elixir maps.
* **SSE**: for sending real-time notifications to the browser for it to update (fetch data).
* **Vue.js** & **axios**: for the front-end. The front-end is a simple Vue.js app (No Vue-CLI was used) that uses axios to fetch data from server.
* **highlight.js**: for syntax highlighting of the requests' bodies.

Finally, the state (data) is kept **in memory** using elixir agents.

The SSE ideas were inspired by this gist: (https://gist.github.com/rbishop/e7b1886d5e75b2f74d8b)


## Limitations

As this was created for practice and learning purposes it has some limitations, like the following:

* The JS code is written with currently supported **ES6** features, so it migh not work with old browsers/versions of browsers.
* If you have multiple tabs with the front-end opened, only the newest/freshest one will get the SSE updates.
  This is because, to keep track of the client connection to send SSE messages I'm currently using _just one value_
  in an Agent; so, everytime a new tab is open or the page is reloaded, that agent updates its value.
* Only supports HTTP requests with forms, JSON, or text (i.e. `text/html`, `application/xml`, `text/plain`, etc.) content types. It supports all `text/*` types, as well as some subtypes: `/plain`, `/xml`, `/javascript`, `/html`, `/css`.
* Vue.js and axios are currently requested from a CDN, so **you need to be online**, even though everything else is done locally. I'm also using Vue in dev mode.
* SSE is used only for notification messages. When data changes, a notification is sent to the client, and it triggers a `GET` call to fetch again **all the requests** from `/requests`. This is simpler to implement, but less efficient.
* In order to keep SSE streams open I **tweaked** the OTP process that's running the `Plug.Connection` so that it `receive`s some custom messages and does a loop (using a tail call). **This might not be a good practice** as it affects the normal behavior of the connection's elixir processes. Although, once the loop is broken, the process continues with the rest of the connection's logic behaving as usual and eventually dying when the request-response cycle is complete.


## Running and using

This assumes you already have **elixir** and **mix** installed in your machine.
If you are running for the first time, make sure to install dependencies using:
```
mix deps.get
```
Once done, you can run with
```
# Running normally...
mix run --no-halt

# ...Or running the server from inside iex (you can interact with iex while the server is running in background)
iex -S mix run
```

Make HTTP requests to http://localhost:5000/endpoint .
Open http://localhost:5000/ to see the front-end with the info of the requests you've made. It updates in automatically when a new request is made, by using SSE internally to fetch the requests JSON from `/requests`.
