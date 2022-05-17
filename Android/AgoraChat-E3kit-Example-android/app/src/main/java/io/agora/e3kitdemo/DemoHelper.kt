package io.agora.e3kitdemo

import android.content.Context
import com.virgilsecurity.android.common.model.Group
import com.virgilsecurity.sdk.cards.Card
import io.agora.chat.ChatClient
import io.agora.chat.ChatOptions
import io.agora.e3kitdemo.e3kit.Device
import io.agora.util.EMLog

class DemoHelper private constructor() {
    companion object {
        val demoHelper: DemoHelper by lazy { DemoHelper() }
    }

    private lateinit var context: Context
    private var device: Device? = null
    private var conversationGroupMap: MutableMap<String, Group?> = HashMap(0)

    fun getContext(): Context {
        return context
    }

    fun getConversationGroupMap(): MutableMap<String, Group?> {
        return conversationGroupMap
    }

    fun getConversationList(): List<String> {
        return conversationGroupMap.keys.toList()
    }

    fun initAgoraSdk(context: Context) {
        this.context = context
        //Initialize Agora Chat SDK
        if (initSDK(context.applicationContext)) {
            // debug mode, you'd better set it to false, if you want release your App officially.
            ChatClient.getInstance().setDebugMode(true)
        }
    }

    private fun initSDK(context: Context): Boolean {
        // Set Chat Options
        val options: ChatOptions = initChatOptions(context) ?: return false

        // Configure custom rest server and im server
        //options.setRestServer(BuildConfig.APP_SERVER_DOMAIN);
        //options.setIMServer("106.75.100.247");
        //options.setImPort(6717);
        options.usingHttpsOnly = true
        ChatClient.getInstance().init(context, options)
        return ChatClient.getInstance().isSdkInited
    }

    private fun initChatOptions(context: Context): ChatOptions {
        val options = ChatOptions()

        // Sets whether to automatically accept friend invitations. Default is true
        options.acceptInvitationAlways = false
        // Set whether read confirmation is required by the recipient
        options.requireAck = true
        // Set whether confirmation of delivery is required by the recipient. Default: false
        options.requireDeliveryAck = true
        // Set whether to delete chat messages when exiting (actively and passively) a group
        return options
    }

    fun initEThree(identity: String, context: Context, callback: () -> Unit) {
        if (null == device) {
            device = Device(identity, context.applicationContext)
            device!!.initialize {
                device!!.register { callback() }
            }
        } else {
            callback()
        }
    }

    fun logout() {
        device!!.logout()
        device = null
    }

    fun loadGroup(groupId: String, groupInitiator: String, callback: (Group?) -> Unit) {
        EMLog.i(
            Constants.TAG,
            "loadGroup groupId=${
                groupId
            },initiator=$groupInitiator"
        )
        device!!.loadGroup(groupId, groupInitiator) {
            callback(it)
        }
    }

    fun createGroup(groupId: String, participants: List<String>, callback: (Group?) -> Unit) {
        EMLog.i(
            Constants.TAG,
            "createGroup groupId=${
                groupId
            },participants=$participants"
        )
        device!!.createGroup(groupId, participants) {
            callback(it)
        }
    }

    fun findUserCard(identity: String, callback: (Card?) -> Unit) {
        device!!.findUsers(listOf(identity)) {
            if (null == it) {
                callback(null)
            } else {
                callback(it[identity]!!)
            }

        }
    }
}