import websocket
import thread
import time
import httplib
import json

# See: https://github.com/liris/websocket-client


def to_socketio(event_name, payload)
    message = {'name': event_name, 'args': [json.dumps(payload)]}
    return "5:::" + json.dumps(message)

def from_socketio(message)
    message = message.replace('5:::', '')
    return json.loads(message)




def recieve_event(ws, name, payload) :
    print "recieve_event: ", name, payload

def send_event(ws, name, payload) :
    ws.send(to_socketio(name, payload))





def on_message(ws, message):
    payload = from_socketio(message)
    recieve_event(ws, payload['name'], payload['args'])

def on_error(ws, error):
    print error

def on_close(ws):
    print "### closed ###"

def on_open(ws):
    def run(*args):
        for i in range(10):
            time.sleep(1)
            send_event(ws, 'StateUpdate', {'counter': i, 'music': 'Punch Brothers'})
        time.sleep(1)
        ws.close()
        print "thread terminating..."
    thread.start_new_thread(run, ())











if __name__ == "__main__":
    websocket.enableTrace(False)

    server = 'localhost'
    port = '9000'

    conn  = httplib.HTTPConnection(server + ":" + str(port))
    conn.request('POST','/socket.io/1/')
    resp  = conn.getresponse() 
    hskey = resp.read().split(':')[0]
    print hskey

    ws = websocket.WebSocketApp('ws://'+server+':'+str(port)+'/socket.io/1/websocket/'+hskey,
                                on_message = on_message,
                                on_error = on_error,
                                on_open = on_open,
                                on_close = on_close)
    ws.run_forever()


