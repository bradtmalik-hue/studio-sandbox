import SwiftUI

struct LoopMomentsView: View {
    @EnvironmentObject var store: LoopStore

    var body: some View {
        NavigationStack {
            Group {
                if store.moments.isEmpty {
                    ContentUnavailableView(
                        "No Moments Yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Share your first photo moment with your loop.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Share your moments, keep your loop")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(Array(store.moments.enumerated()), id: \.offset) { _, moment in
                                LoopMomentCard(moment: moment)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Moments")
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}

struct LoopMomentCard: View {
    let moment: LoopMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(moment.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .cornerRadius(12)

            Text(moment.caption)
                .font(.body)
                .multilineTextAlignment(.leading)

            Text(moment.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
    }
}

struct LoopChatsView: View {
    @EnvironmentObject var store: LoopStore

    var body: some View {
        NavigationStack {
            Group {
                if store.messages.isEmpty {
                    ContentUnavailableView(
                        "No Chats Yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a quick chat with your close friends.")
                    )
                } else {
                    List {
                        ForEach(Array(store.messages.enumerated()), id: \.offset) { _, message in
                            LoopMessageRow(message: message)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Chats")
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}

struct LoopMessageRow: View {
    let message: LoopMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                Text(message.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct LoopPeopleView: View {
    @EnvironmentObject var store: LoopStore

    var body: some View {
        NavigationStack {
            Group {
                if store.members.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2.slash",
                        description: Text("Invite close friends to your loop.")
                    )
                } else {
                    List {
                        ForEach(Array(store.members.enumerated()), id: \.offset) { _, member in
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                Text(member.name)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("People")
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}