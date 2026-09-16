import SwiftUI

/// The "chest" tab: the player's talents and the gift cards they can buy with them.
struct CollectionView: View {
    @Environment(GameStore.self) private var store

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let s = store.strings
        let ownedCount = store.content.gifts.filter { store.ownsCard($0) }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(s.tabCollection)
                        .font(.heading(28))
                        .foregroundStyle(Color.text)
                    Spacer()
                    Text(s.cardsOwned(ownedCount, store.content.gifts.count))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gold)
                }

                // Balance card
                HStack(spacing: 12) {
                    TalentCoin(size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.talentsBalance(store.talents))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.text)
                        Text(s.chestHint)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.muted)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
                .padding(.top, 14)

                HStack(spacing: 5) {
                    Text(s.collectionIntro)
                    TalentCoin(size: 14)
                    Text("\(GameStore.cardPrice)")
                        .fontWeight(.bold)
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.muted)
                .padding(.vertical, 14)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.content.gifts, id: \.emoji) { gift in
                        GiftCard(gift: gift)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.bg)
    }
}

struct GiftCard: View {
    @Environment(GameStore.self) private var store
    let gift: Gift

    var body: some View {
        let s = store.strings
        let owned = store.ownsCard(gift)
        let affordable = store.canBuyCard(gift)
        VStack(spacing: 8) {
            Text(gift.emoji)
                .font(.system(size: 44))
                .grayscale(owned ? 0 : 1)
                .opacity(owned ? 1 : 0.45)
                .padding(.top, 6)
            Text(gift.name(store.lang))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 34)

            if owned {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text(s.owned)
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            } else {
                Button {
                    store.buyCard(gift)
                } label: {
                    HStack(spacing: 5) {
                        Text(s.buy)
                        TalentCoin(size: 14)
                        Text("\(GameStore.cardPrice)")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(affordable ? Color.brandInk : Color.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(affordable ? Color.brand : Color.bg, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(affordable ? Color.brand : Color.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!affordable)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(owned ? Color.gold : Color.border, lineWidth: owned ? 1.5 : 1))
    }
}
