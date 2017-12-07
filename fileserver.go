package main

import (
  "log"
  "net/http"
)

func main() {
  http.Handle("/files/", http.StripPrefix("/files", http.FileServer(http.Dir("files"))))
  err := http.ListenAndServe(":12345", nil)
  if err != nil {
    log.Fatal("ListenAndServe: ", err)
  }

}

