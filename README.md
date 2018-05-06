# Request Inspector

A basic application for inspecting HTTP requests. I made this project for practice and learning
purposes, with the aim of getting a little more experience with Elixir. It uses the following technologies:

* **Plug**: as the server with only a router and a few routes, and a custom `text/*` parser.
* **Poison**: for encoding/decoding between JSON and elixir maps.
* **SSE**: for sending real-time notifications to browser that it should update (fetch data); it doesn't send the new data.
* **Vue.js** & **axios**: for the front-end. The front-end is a simple Vue.js app (No Vue-CLI was used) that uses axios to fetch data from server.

Finally, the state (data) is kept in memory using Agents.

The SSE ideas where inspired by this gist: (https://gist.github.com/rbishop/e7b1886d5e75b2f74d8b)


## Limitations

As this was created for practice and learning purposes it has some limitations, like the following:

* If you have multiple tabs with the front-end opened, only the newest/freshest one will get the SSE updates.
  This is because, to keep track of the client connection to send SSE messages I'm currently using just one value
  in an Agent, so everytime a new tab is open or reloaded that agent updates its value to the new client.
* Only supports HTTP requests with form, JSON, or `text/*` (i.e. `text/html`, `text/xml`, `text/plain`, etc.) content types.
* Vue.js and axios are currently requested from a CDN, so you need to be online, even though everything else is done locally.
* In order to keep SSE streams open I **tweaked** the process running the `Connection` so that it `receive`s some custom messages and does a loop. 
  **This might not be a good practice** as it affects the normal behaviour of the connection processes. Although, once the loop is broken, the
  the process continues the rest of the request behaving as usual.


## Running and using

This assumes you already have Elixir and mix installed in your machine.
If you are running for the first time, make sure to install dependencies using:
```
mix deps.get
```
Once done, you can run with
```
# Running normally
mix run --no-halt

#Run the server from inside iex (you can interact with iex while the server is running in background)
iex -S mix run
```

Make HTTP requests to http://localhost:5000/endpoint .
Open http://localhost:5000/ to see the front-end with the info of the requests you've made. It updates
in automatically when a new request is made, by using SSE internally.