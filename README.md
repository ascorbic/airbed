# Airbed
## A lightweight CouchDB Actionscript 3 client library for Adobe AIR

CouchDB has a very simple RESTful API, so it's quite possible to interact with it just using basic HTTP classes. 
However, that can get a little cumbersome so a library can help. This is designed to be as "close to the metal" as possible, with just a few convenience features such as session handling and change watching. If you need more features such as DAO mapping and support for non-AIR use, try [https://github.com/bustardcelly/as3couchdb](as3couchdb).

It also includes a UUID class which generates genuine unique values. This can be guaranteed because the hashed string includes the machine's MAC address.

### Usage

For the full API, look at the comments. This is a basic example of logging-in, watching for changes and adding a document.

    var server:CouchServer = new CouchServer('http://127.0.0.1:5984/');

    server.addEventListener(CouchEvent.CHANGE, function(e:CouchEvent):void {
        trace('Change received: ' + e.data.id);
    });
    
    server.login('username', 'password', function(e:CouchEvent):void {
        server.watchChanges('test');
        addItem({foo: 'bar'});
    });
    
    function addItem(item:Object):void {
        if(server.loggedIn) {
            var obj:String = "test/" + UUID.generate();
            server.put(obj, item, startUpload);
        }
    }

    function startUpload(e:CouchEvent, l:URLLoader):void {
       var file:File = new File();
       file.browseForOpen("Upload");
       
       /* You can watch for progress events on the file object, or attach it to a ProgressBar */
       
       file.addEventListener(Event.SELECT, function (event:Event):void {
          server.upload('test/' + e.data.id, e.data.rev, file.name, 'application/octet-stream', file, function(e:CouchEvent, f:FileReference):void {
             trace('sent file');
          });

       });
    }
 
### Requirements
[as3corelib](http://code.google.com/p/as3corelib/) for JSON handling, SHA1 and events.

The `UUID` class requires Flex 4 and Adobe AIR 2.

### Bugs and contributions
If you have a patch, fork the Github repo and send me a pull request. Submit bug reports on GitHub, please. 

### Credits

By [Matt Kane](https://github.com/ascorbic)

### License 

(The MIT License)

Copyright (c) 2010 [CLEVR Ltd](http://www.clevr.ltd.uk/)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.