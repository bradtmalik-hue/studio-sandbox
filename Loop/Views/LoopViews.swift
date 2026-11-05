import SwiftUI
import Combine
import Foundation

// MARK: - Moment Card

struct LoopMomentCard: View {
    let moment: LoopMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageName = moment.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipped()
                    .cornerRadius(12)
            }
            Text(moment.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text(moment.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Message Bubble

struct LoopMessageBubble: View {
    let message: LoopMessage

    var body: some View {
        HStack {
            if message.sender == "Me" {
                Spacer(minLength: 40)
            }
            VStack(alignment: message.sender == "Me" ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(message.sender == "Me" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.sender == "Me" ? .white : .primary)
                    .cornerRadius(16)
                Text("\(message.sender) • \(message.sentAt, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if message.sender != "Me" {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Moments Feed

struct LoopMomentsView: View {
    @EnvironmentObject var store: LoopStore
    @State private var showingCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if store.moments.isEmpty {
                    ContentUnavailableView(
                        "No Moments Yet",
                        systemImage: "bubble.left",
                        description: Text("Share your first moment to start a conversation.")
                    )
                } else {
                    List(store.moments) { moment in
                        NavigationLink(destination: LoopMomentDetailView(moment: moment)) {
                            LoopMomentCard(moment: moment)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Moments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCompose = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                LoopComposeView()
            }
        }
    }
}

// MARK: - Conversations Inbox

struct LoopConversationsView: View {
    @EnvironmentObject var store: LoopStore

    var body: some View {
        NavigationStack {
            Group {
                if store.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Conversations you start about moments will appear here.")
                    )
                } else {
                    List(store.conversations) { conversation in
                        NavigationLink(destination: LoopConversationDetailView(conversation: conversation)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(momentText(for: conversation))
                                    .font(.headline)
                                if let last = conversation.messages.last {
                                    Text(last.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Conversations")
        }
    }

    private func momentText(for conversation: LoopConversation) -> String {
        if let moment = store.moments.first(where: { $0.id == conversation.momentId }) {
            return moment.text
        } else {
            return "Moment"
        }
    }
}

// MARK: - Compose New Moment

struct LoopComposeView: View {
    @EnvironmentObject var store: LoopStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedImageName = "sample1"
    private let imageOptions = ["sample1", "sample2", "sample3", "sample4"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Moment") {
                    TextField("What's on your mind?", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Image") {
                    Picker("Image", selection: $selectedImageName) {
                        ForEach(imageOptions, id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .tag(name)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Moment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        store.moments.append(LoopMoment(text: text, imageName: selectedImageName))
                        store.save()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Moment Detail with Conversation

struct LoopMomentDetailView: View {
    @EnvironmentObject var store: LoopStore
    let moment: LoopMoment
    @State private var messageText = ""

    private var conversation: LoopConversation? {
        store.conversations.first(where: { $0.momentId == moment.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Moment content
                VStack(alignment: .leading, spacing: 10) {
                    if let imageName = moment.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 260)
                            .clipped()
                            .cornerRadius(12)
                    }
                    Text(moment.text)
                        .font(.title2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(moment.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)

                Divider()

                if let conversation = conversation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conversation")
                            .font(.headline)
                        ForEach(conversation.messages) { message in
                            LoopMessageBubble(message: message)
                        }
                    }

                    HStack {
                        TextField("Message", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                        Button("Send") {
                            sendMessage(in: conversation)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Conversation Yet",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Start a conversation about this moment.")
                        )
                        Button("Start Conversation") {
                            store.conversations.append(LoopConversation(momentId: moment.id))
                            store.save()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage(in conversation: LoopConversation) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let index = store.conversations.firstIndex(where: { $0.id == conversation.id }) {
            store.conversations[index].messages.append(LoopMessage(text: messageText, sender: "Me"))
            store.save()
        }
        messageText = ""
    }
}

// MARK: - Conversation Detail

struct LoopConversationDetailView: View {
    @EnvironmentObject var store: LoopStore
    let conversation: LoopConversation
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(conversation.messages) { message in
                        LoopMessageBubble(message: message)
                    }
                }
                .padding()
            }
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    sendMessage()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("Conversation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let index = store.conversations.firstIndex(where: { $0.id == conversation.id }) {
            store.conversations[index].messages.append(LoopMessage(text: messageText, sender: "Me"))
            store.save()
        }
        messageText = ""
    }
}