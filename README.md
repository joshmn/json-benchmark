# README

JSON Benchmark. 

## About

Does benchmarkings for a large number of records.

Uses various serialization patterns (see homes_controller.rb) — each has a flag of `kind` — such as ActiveModelSerializers, Fast JSON-API, etc. 

## Installation

Install ApacheBench.

`bundle`
`rails db:create db:migrate db:seed` 
`rails server RAILS_ENV=production`

Then,

`ruby superbench.rb -n 10 -a --limit 100000`

This will run 10 requests on apachebench to /homes.json?limit=100000 and then output the results to "result-$kind.txt" along with various logs (development server log, the response body builder from the controller)

