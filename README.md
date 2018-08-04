# Request Inspector

Basic application for inspecting HTTP requests. I made this project for practice and learning purposes, with the aim of getting more experience with Elixir and some tools.

<img src="https://i.imgur.com/pcwBecA.gif" height="512px"/>


It uses the following technologies:

* **Plug**: as the server, with a router and a custom plug parser for text content.
* **Poison**: for encoding/decoding between JSON and Elixir's maps.
* **SSE**: for sending real-time notifications to the browser for it to update (fetch data again). The SSE ideas were inspired by this gist: (https://gist.github.com/rbishop/e7b1886d5e75b2f74d8b) (with some additions and workarounds).
* **Vue.js** & **axios**: for the front-end. The front-end is a simple Vue.js app (Vue-CLI wasn't used) that uses axios to make HTTP requests.
* **highlight.js**: for syntax highlighting in the front-end.

## Limitations

Bear in mind that it has some limitations, like the following:

* All state (data) is kept **in-memory** using Elixir agents.
* The JS code is written with currently supported **ES6** features, so it doesn't work with old browsers/versions of browsers.
* If you have multiple tabs with the front-end opened, **only the newest/freshest one will get the real-time updates**. This is because, to keep track of the client connection to send SSE messages, I'm currently using _just one value_ (the connection's pid) in an Agent; so, everytime a new tab is open or the page is reloaded, that agent updates its value.
* Only supports HTTP requests with forms, JSON, or text (i.e. `text/html`, `application/xml`, `text/plain`, etc.) content types. It supports all `text/*` types, as well as some subtypes: `/plain`, `/xml`, `/javascript`, `/html`, `/css`.
* Vue.js and axios are currently requested from a CDN, so **you need to be online**, even though everything else is done locally. I'm also using Vue in dev mode.
* SSE is used **only for notification messages**. When data changes, a notification is sent to the client, and it triggers a `GET` call to fetch again **all the requests** from `/requests`. This is simpler to implement, but less efficient.
* In order to keep SSE streams open I **tweaked/hijacked** the OTP process that's running the `Plug.Connection` so that it `receive`s some custom Elixir messages and does a loop (using a tail call). **This might not be a good practice** as it affects the normal behavior of the connection's Elixir processes. When updated to Cowboy2, I had to modify it's idle connection's timeout to avoid the connection getting closed after 60s. However, once the loop is broken, the process continues with the rest of the connection's lifecycle, behaving as usual and, eventually, dying when the request-response cycle is complete and the connection gets close.


## Running and using

### Running
This assumes you already have **Elixir** and **Mix** installed in your machine. If you are running for the first time, make sure to install dependencies using:
```
$ mix deps.get
```
Once done, you can run the server either of these ways:
**Run normally...**
```
$ mix run --no-halt
```
**...Or run the server from inside iex (you can interact with iex while the server is running in background)**
```
$ iex -S mix run
```

### Using
* Open http://localhost:5000/ to see the app's front-end. You can create buckets from there.
* Buckets have a key (id of 8 characters) and expose the routes `/endpoint`, `/sse`, and `/requests`.
* Create a bucket (by requesting a new key) and make HTTP requests to `/buckets/:key/endpoint`, where `key` is the id of the bucket (i.e. http://localhost:5000/buckets/o4c5padn/endpoint). Ids are random alphanumeric strings of 8 characters.

Also, take into account that this doesn't have to be accessed from localhost; feel free to connect from other machines and use the server's IP address instead of localhost, although still using port 5000 (it's currently hard-coded).
