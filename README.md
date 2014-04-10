batpoo
======

This is based on part of the [Maneuverable Web Architecture][3] at QCon London by [Michael Nygaard][1].

There are three parts to it:

## 'at' service

Calls the specified url at a given point in time (omly works for now...)

`curl -X POST -d @test_at_call.json http://localhost:4567/at`

## script factory

Builds a script to do a specified, stores it in mongo, and returns a url for the
script.

`curl -X POST -d @test_factory_call.json http://localhost:4567/script/factory`

## script engine

Runs the scripts built by the factory

### to run script :id

`curl http://localhost:4567/script/:id/run`  

### to run an abritrary script

`curl -X POST -d @test_script.json http://localhost:4567/script/run`

## Dependencies

You will need to be running mongodb on your local machine. Also you will need
an SMTP server listening on port 8025 (I used [FakeSMTP][2])

 [1]: http://www.michaelnygard.com/
 [2]: http://nilhcem.github.io/FakeSMTP/
 [3]: https://speakerdeck.com/mtnygard/maneuverable-web-architecture
