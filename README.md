typhoon
=======

This is based on part of the [Maneuverable Web Architecture][3] at QCon London by [Michael Nygaard][1].

There are three parts to it:

## 'at' service

Calls the specified url at a given point in time. I have used the [chronic][4] gem to
parse the date, so it can make sense of pretty much anything...

`curl -X POST -d @test_at_call.json http://localhost:4567/at`

example:

```json
{
  "at": "now",
  "url": "http://localhost:4567/script/534669f6ba8d2c8c91000001/run"
}
```

The URL and the time to call it are stored in a database, and I use [beanstalk][6] and
[clockwise][7] to call the url when the time comes.

## script factory

Builds a script to do a specified task, stores it in a key/value store (using [moneta][8]), and returns a url for the
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

## Creating the database

from the project's root directory:

```
typingincolor:typhoon andrew$ irb
irb(main):001:0> require './model/Task.rb'
=> true
irb(main):002:0> DataMapper.auto_migrate!
=> DataMapper
irb(main):003:0> quit
```

## Running the scheduled tasks

You will need beanstalk (`brew install beanstalk`)

```
> beanstalkd &
> bundle exec clockwork clock.rb
> bundle exec stalk jobs.rb
```

Alternatively, start beanstalkd and use [foreman][5]

 [1]: http://www.michaelnygard.com/
 [2]: http://nilhcem.github.io/FakeSMTP/
 [3]: https://speakerdeck.com/mtnygard/maneuverable-web-architecture
 [4]: https://github.com/mojombo/chronic
 [5]: https://github.com/ddollar/foreman
 [6]: http://kr.github.io/beanstalkd/
 [7]: https://github.com/tomykaira/clockwork
 [8]: https://github.com/minad/moneta
