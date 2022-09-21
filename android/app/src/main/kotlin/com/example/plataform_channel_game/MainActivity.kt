package com.example.plataform_channel_game

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.util.Log
import com.pubnub.api.PNConfiguration
import com.pubnub.api.PubNub
import com.pubnub.api.callbacks.SubscribeCallback
import com.pubnub.api.models.consumer.PNStatus
import com.pubnub.api.models.consumer.objects_api.channel.PNChannelMetadataResult
import com.pubnub.api.models.consumer.objects_api.membership.PNMembershipResult
import com.pubnub.api.models.consumer.objects_api.uuid.PNUUIDMetadataResult
import com.pubnub.api.models.consumer.pubsub.PNMessageResult
import com.pubnub.api.models.consumer.pubsub.PNPresenceEventResult
import com.pubnub.api.models.consumer.pubsub.PNSignalResult
import com.pubnub.api.models.consumer.pubsub.files.PNFileEventResult
import com.pubnub.api.models.consumer.pubsub.message_actions.PNMessageActionResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity: FlutterActivity() {

    private val CHANNEL_NATIVE_DART = "game/exchange"
    private var pubnub: PubNub? = null
    private var channel_pubnub: String? = null
    private var handler: Handler? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handler = Handler(Looper.getMainLooper());
        val pnConfiguration = PNConfiguration("myUuid");
        pnConfiguration.subscribeKey = "sub-c-3c3b5999-7b48-45c0-8f39-5becd2f7c486";
        pnConfiguration.publishKey = "pub-c-6e2f827c-0508-4196-af39-203e6202c89e";
        pubnub = PubNub(pnConfiguration)
        Log.e("PubNub", "teve erro? ${pubnub}")

        pubnub?.let {
            it.addListener(object: SubscribeCallback(){
                override fun message(pubnub: PubNub, pnMessageResult: PNMessageResult) {

                }
                override fun status(pubnub: PubNub, pnStatus: PNStatus) {}
                override fun presence(pubnub: PubNub, pnPresenceEventResult: PNPresenceEventResult) {}
                override fun signal(pubnub: PubNub, pnSignalResult: PNSignalResult) {}
                override fun uuid(pubnub: PubNub, pnUUIDMetadataResult: PNUUIDMetadataResult) {}
                override fun channel(pubnub: PubNub, pnChannelMetadataResult: PNChannelMetadataResult) {}
                override fun membership(pubnub: PubNub, pnMembershipResult: PNMembershipResult) {}
                override fun messageAction(pubnub: PubNub,pnMessageActionResult: PNMessageActionResult) {}
                override fun file(pubnub: PubNub, pnFileEventResult: PNFileEventResult) {}
            })
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NATIVE_DART
        ).setMethodCallHandler {
                call, result ->
            if(call.method == "subscribe"){
                subscribeChannel(call.argument("channel"))
                Log.e("Chegou no nativo", "subscribe")
                result.success(true)
            }else if (call.method == "sendAction"){
                pubnub!!.publish()
                    .message(call.arguments)
                    .channel(channel_pubnub)
                    .async{
                        result, status -> Log.e("PubNub", "teve erro? ${status.isError}")
                    }
                Log.e("Chegou no nativo", "enviou a mensagem")
                result.success(true)
            } else{
                result.notImplemented()
            }
        }
    }

    private fun subscribeChannel(channel: String?){
        channel_pubnub = channel
        channel_pubnub.let {
            pubnub?.subscribe()?.channels(Arrays.asList(channel))?.execute()
        }
    }
}
