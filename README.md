typhoon
=======

This is based on part of the [Maneuverable Web Architecture][3] at QCon London by [Michael Nygaard][1].

There are three parts to it:

## 'at' service

Calls the specified url at a given point in time (only works for "now"...)

`curl -X POST -d @test_at_call.json http://localhost:4567/at`

example:

```json
{
  "at": "now",
  "url": "http://localhost:4567/script/534669f6ba8d2c8c91000001/run"
}
```

## script factory

Builds a script to do a specified task, stores it in mongo, and returns a url for the
script.

`curl -X POST -d @test_factory_call.json http://localhost:4567/script/factory`

example request:

```json
{
  "action": "send_email",
  "data": {
    "to": "abraithw@gmail.com",
    "subject": "Hello",
    "name": "Andrew"
  }
}
```

## script engine

Runs the scripts built by the factory

### to run script :id

`curl http://localhost:4567/script/:id/run`  

### to run an abritrary script

`curl -X POST -d @test_script.json http://localhost:4567/script/run`

example script:

```json
{
    "one": {
        "command": "erb",
        "data": {
            "template": "email",
            "template_data": {
                "name": "Andrew"
            }
        }
    },
    "two": {
        "command": "email",
        "data": {
            "to": "abraithw@gmail.com",
          	"subject": "test email"
        }
    }
}
```


## Dependencies

You will need to be running mongodb on your local machine. Also you will need
an SMTP server listening on port 8025 (I used [FakeSMTP][2])

 [1]: http://www.michaelnygard.com/
 [2]: http://nilhcem.github.io/FakeSMTP/
 [3]: https://speakerdeck.com/mtnygard/maneuverable-web-architecture
