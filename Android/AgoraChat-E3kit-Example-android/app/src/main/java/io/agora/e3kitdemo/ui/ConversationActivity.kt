package io.agora.e3kitdemo.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.view.*
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.MessageListener
import io.agora.chat.ChatClient
import io.agora.chat.ChatMessage
import io.agora.chat.Conversation
import io.agora.e3kitdemo.Constants
import io.agora.e3kitdemo.DemoHelper
import io.agora.e3kitdemo.R
import io.agora.e3kitdemo.base.BaseActivity
import io.agora.e3kitdemo.databinding.ActivityConversationBinding
import io.agora.util.EMLog
import java.util.*


class ConversationActivity : BaseActivity() {
    private lateinit var binding: ActivityConversationBinding
    private var actionBar: ActionBar? = null
    private lateinit var adapter: ConversationListAdapter
    private lateinit var allConversations: Map<String, Conversation>
    private lateinit var conversationIdList: List<String>
    private var conversationIdIndex: Int = 0

    companion object {
        const val MESSAGE_UPDATE_GROUP = 1
    }

    private val mHandler: Handler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            when (msg.what) {
                MESSAGE_UPDATE_GROUP -> {
                    conversationIdIndex++
                    if (conversationIdIndex < conversationIdList.size) {
                        updateConversationGroupInfo(conversationIdList[conversationIdIndex])
                    } else {
                        binding.loading.visibility = View.GONE
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        actionBar = supportActionBar
        actionBar!!.setHomeButtonEnabled(true)
        actionBar!!.setDisplayHomeAsUpEnabled(true)
        binding = ActivityConversationBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)
        initView()
        initListener()
        initData();
    }

    private fun initView() {
        actionBar!!.title = "All Conversations"

        binding.conversationList.layoutManager = LinearLayoutManager(this)
        val divider = DividerItemDecoration(this, DividerItemDecoration.VERTICAL)
        ContextCompat.getDrawable(this, R.drawable.message_list_divider)?.let {
            divider.setDrawable(
                it
            )
        }
        binding.conversationList.addItemDecoration(divider)

        adapter = ConversationListAdapter()
        binding.conversationList.adapter = adapter
    }

    override fun onResume() {
        super.onResume()

    }

    private fun initListener() {
        adapter.setOnItemClickListener(object : OnItemClickListener {
            override fun onItemClick(position: Int) {
                if (DemoHelper.demoHelper.getConversationList()[position].isNotEmpty()) {
                    val intent = Intent(this@ConversationActivity, ChatActivity::class.java)
                    intent.putExtra(
                        Constants.SEND_TO,
                        DemoHelper.demoHelper.getConversationList()[position]
                    )
                    startActivity(intent)
                } else {
                    EMLog.i(Constants.TAG, "group info is null")
                }
            }
        })
        ChatClient.getInstance().chatManager().addMessageListener(object : MessageListener {
            override fun onMessageReceived(messages: MutableList<ChatMessage>?) {
                runOnUiThread { initData() }

            }

            override fun onCmdMessageReceived(messages: MutableList<ChatMessage>?) {
                TODO("Not yet implemented")
            }

            override fun onMessageRead(messages: MutableList<ChatMessage>?) {
                TODO("Not yet implemented")
            }

            override fun onMessageDelivered(messages: MutableList<ChatMessage>?) {
                TODO("Not yet implemented")
            }

            override fun onMessageRecalled(messages: MutableList<ChatMessage>?) {
                TODO("Not yet implemented")
            }
        })

        binding.loading.setOnTouchListener { v, event -> true }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                finish() // back button
                return true
            }
            R.id.send_to -> {
                val sendToEt = EditText(this)
                val builder = AlertDialog.Builder(this)
                builder.setTitle("Send to")
                builder.setView(sendToEt)
                builder.setPositiveButton(android.R.string.yes) { dialog, which ->
                    if (sendToEt.text.toString().isNotEmpty()) {
                        binding.loading.visibility = View.VISIBLE
                        val sendTo = sendToEt.text.toString()
                        val conversation = ChatClient.getInstance().chatManager()
                            .getConversation(sendTo, Conversation.ConversationType.Chat, true)
                        conversation.extField = ChatClient.getInstance().currentUser

                        var groupId =
                            ChatClient.getInstance().currentUser.toLowerCase(Locale.ROOT) + sendTo.toLowerCase(
                                Locale.ROOT
                            ) + "agorachat"
                        val charArray = groupId.toCharArray()
                        Arrays.sort(charArray)
                        groupId = String(charArray)

                        DemoHelper.demoHelper.createGroup(
                            groupId,
                            listOf(sendTo)
                        ) {
                            if (null == it) {
                                runOnUiThread {
                                    binding.loading.visibility = View.GONE
                                    dialog.dismiss()
                                }
                            } else {
                                runOnUiThread {
                                    binding.loading.visibility = View.GONE
                                    DemoHelper.demoHelper.getConversationGroupMap()[conversation.conversationId()] =
                                        it
                                    adapter.setConversationIdList(DemoHelper.demoHelper.getConversationList())
                                    val intent =
                                        Intent(
                                            this@ConversationActivity,
                                            ChatActivity::class.java
                                        ).apply {
                                            putExtra(Constants.SEND_TO, sendTo)
                                        }
                                    startActivity(intent)
                                    dialog.dismiss()
                                }
                            }
                        }
                    }
                }
                builder.setNegativeButton(android.R.string.no) { dialog, which ->
                    dialog.dismiss()
                }
                builder.show()
                return true
            }
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        val inflater = menuInflater
        inflater.inflate(R.menu.conversation_menu, menu)
        return super.onCreateOptionsMenu(menu)
    }

    private fun initData() {
        allConversations = ChatClient.getInstance().chatManager().allConversations
        conversationIdList = allConversations.keys.toList()
        allConversations.forEach {
            DemoHelper.demoHelper.getConversationGroupMap()[it.key] = null
        }
        adapter.setConversationIdList(DemoHelper.demoHelper.getConversationList())

        if (conversationIdList.isNotEmpty()) {
            initGroupInfo()
        }
    }

    private fun initGroupInfo() {
        binding.loading.visibility = View.VISIBLE
        conversationIdIndex = 0;
        updateConversationGroupInfo(conversationIdList[conversationIdIndex])
    }

    private fun updateConversationGroupInfo(conversationId: String) {
        val conversation = allConversations[conversationId]
        val lastMessage = conversation?.lastMessage
        if (null != lastMessage) {
            var groupId = lastMessage.from.toLowerCase(Locale.ROOT) + lastMessage.to.toLowerCase(
                Locale.ROOT
            ) + "agorachat"

            var groupInitiator = conversation.extField
            if (groupInitiator.isEmpty()) {
                groupInitiator = lastMessage.from
                ChatClient.getInstance().chatManager().getConversation(conversationId).extField =
                    groupInitiator
            }
            val charArray = groupId.toCharArray()
            Arrays.sort(charArray)
            groupId = String(charArray)

            DemoHelper.demoHelper.loadGroup(
                groupId,
                groupInitiator
            ) { group ->
                DemoHelper.demoHelper.getConversationGroupMap()[conversationId] = group
                mHandler.sendEmptyMessage(MESSAGE_UPDATE_GROUP)
            }
        }
    }

    inner class ConversationListAdapter :
        RecyclerView.Adapter<ConversationListAdapter.ConversationViewHolder>() {
        private var conversationIdList: List<String> = ArrayList(0)
        private var itemClickListener: OnItemClickListener? = null

        fun setConversationIdList(list: List<String>) {
            conversationIdList = list
            notifyDataSetChanged()
        }

        fun setOnItemClickListener(itemClickListener: OnItemClickListener) {
            this.itemClickListener = itemClickListener
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ConversationViewHolder {
            val view =
                LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_conversation_list, parent, false)
            return ConversationViewHolder(view)
        }

        override fun onBindViewHolder(holder: ConversationViewHolder, position: Int) {
            holder.conversationId.text = conversationIdList[position]
            holder.itemView.setOnClickListener { itemClickListener!!.onItemClick(position) }
        }

        override fun getItemCount(): Int {
            return conversationIdList.size
        }

        inner class ConversationViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val conversationId: TextView = view.findViewById(R.id.conversation_id)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mHandler.removeCallbacksAndMessages(null)
    }

    interface OnItemClickListener {
        fun onItemClick(position: Int)
    }
}

