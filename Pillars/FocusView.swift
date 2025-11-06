//
//  FocusView.swift
//  Pillars
//
//  Created by Alex McGregor on 11/4/25.
//

import SwiftUI

struct FocusView: View {
    @ObservedObject var focusStore: FocusStore
    @State private var selectedDate: Date = Date()
    @State private var showingJournalSheet = false
    @State private var journalText: String = ""
    @State private var showTestSplash = false
    @Environment(\.colorScheme) var colorScheme

    private var selectedFocusId: Int? {
        focusStore.getFocus(for: selectedDate)?.choiceId
    }

    private var selectedFocusChoice: FocusChoice? {
        guard let id = selectedFocusId else { return nil }
        return FocusChoice.defaultChoices.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationView {
            ZStack {
                FocusGradientBackground(
                    focusColor: selectedFocusChoice?.color.color,
                    colorScheme: colorScheme
                )

                ScrollView {
                    VStack(spacing: 24) {
                        // Header section with focus info
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Spacer(minLength: 100)
                    }
                }
                .scrollContentBackground(.hidden)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            // Only navigate if swipe is more horizontal than vertical
                            if abs(horizontalAmount) > abs(verticalAmount) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if horizontalAmount < 0 {
                                        // Swipe left - next day
                                        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                            selectedDate = nextDay
                                        }
                                    } else {
                                        // Swipe right - previous day
                                        if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                            selectedDate = prevDay
                                        }
                                    }
                                }
                            }
                        }
                )

                // Floating buttons in bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        VStack(spacing: 16) {
                            // Test button for splash screen
                            Button(action: {
                                showTestSplash = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)

                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(for: colorScheme))
                                }
                                .frame(width: 44, height: 44)
                            }

                            // Journal button
                            floatingJournalButton
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }

                // Test splash screen overlay
                if showTestSplash {
                    DailyFocusSplash(focusStore: focusStore, isPresented: $showTestSplash)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .navigationTitle(actualDateString)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FocusMenuButton(focusStore: focusStore, selectedDate: selectedDate)
                }
            }
        }
        .sheet(isPresented: $showingJournalSheet) {
            journalEntrySheet
                .presentationDetents([.height(80), .large])
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.disabled)
                .presentationBackground(.regularMaterial)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            // Load existing journal entry if there is one
            journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
        }
        .onChange(of: selectedDate) { _ in
            // Update journal text when date changes
            journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            if let choice = selectedFocusChoice {
                // Color dot next to focus name
                Circle()
                    .fill(choice.color.color)
                    .frame(width: 8, height: 8)

                Text(choice.label)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)

                if let relativeDayText = relativeDayText {
                    Text("•")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.tertiary)
                    Text(relativeDayText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("No focus set")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)

                if let relativeDayText = relativeDayText {
                    Text("•")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.tertiary)
                    Text(relativeDayText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var floatingJournalButton: some View {
        Button(action: {
            showingJournalSheet = true
        }) {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)

                // Icon
                let hasEntry = focusStore.getJournalEntry(for: selectedDate) != nil
                Image(systemName: hasEntry ? "note.text" : "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.primaryText(for: colorScheme))
            }
            .frame(width: 56, height: 56)
        }
    }

    private var journalEntrySheet: some View {
        MessageStyleJournalView(
            text: $journalText,
            selectedDate: selectedDate,
            accentColor: getJournalEntryColor(for: selectedDate),
            onSave: {
                focusStore.setJournalEntry(for: selectedDate, entry: journalText)
                showingJournalSheet = false
            },
            onCancel: {
                journalText = focusStore.getJournalEntry(for: selectedDate) ?? ""
                showingJournalSheet = false
            }
        )
    }

    private func getJournalEntryColor(for date: Date) -> Color {
        guard let focus = focusStore.getFocus(for: date),
              let choice = FocusChoice.defaultChoices.first(where: { $0.id == focus.choiceId }) else {
            return Color.blue
        }
        return choice.color.color
    }

    private var actualDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: selectedDate)

        let day = Calendar.current.component(.day, from: selectedDate)
        let suffix = ordinalSuffix(for: day)

        return "\(monthName) \(day)\(suffix)"
    }

    private func ordinalSuffix(for day: Int) -> String {
        let lastDigit = day % 10
        let lastTwoDigits = day % 100

        // Special cases for 11th, 12th, 13th
        if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
            return "th"
        }

        // Otherwise, use the last digit
        switch lastDigit {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    private var relativeDayText: String? {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        return nil
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func fullDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// Message-style journal view (like iMessage)
struct MessageStyleJournalView: View {
    @Binding var text: String
    let selectedDate: Date
    let accentColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            MessageInputViewRepresentable(
                text: $text,
                accentColor: accentColor,
                onSave: onSave
            )
            .background(Color(UIColor.systemBackground))
            .padding(.bottom, keyboardHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.clear)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
}

// UIKit-based message input view that sits on keyboard
struct MessageInputViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let accentColor: Color
    let onSave: () -> Void

    func makeUIView(context: Context) -> MessageInputContainerView {
        let view = MessageInputContainerView()
        view.accentColor = accentColor
        view.onSave = onSave
        view.textView.delegate = context.coordinator
        // Set text first, then update placeholder
        view.textView.text = text
        view.updatePlaceholder()
        view.updateSendButton()
        return view
    }

    func updateUIView(_ uiView: MessageInputContainerView, context: Context) {
        uiView.accentColor = accentColor
        uiView.onSave = onSave
        if uiView.textView.text != text {
            uiView.textView.text = text
            // Trigger height update and placeholder update when text changes from outside
            uiView.textDidChange()
            uiView.updatePlaceholder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MessageInputViewRepresentable

        init(_ parent: MessageInputViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            // Update send button state
            if let containerView = textView.superview?.superview as? MessageInputContainerView {
                containerView.updateSendButton()
            }
        }
    }
}

// UIKit container view that mimics iMessage input
class MessageInputContainerView: UIView {
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerRadius = 18
        textView.backgroundColor = UIColor.systemGray5
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        return textView
    }()

    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.systemGray3
        button.isEnabled = false
        return button
    }()

    var textViewHeightConstraint: NSLayoutConstraint!
    var containerHeightConstraint: NSLayoutConstraint!
    var placeholderLabel: UILabel!
    var accentColor: Color = .blue {
        didSet {
            updateSendButton()
        }
    }
    var onSave: (() -> Void)?

    override var intrinsicContentSize: CGSize {
        let textViewHeight = textViewHeightConstraint.constant
        let containerHeight = textViewHeight + 24 // 12 padding top + 12 padding bottom
        return CGSize(width: UIView.noIntrinsicMetric, height: max(60, containerHeight))
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.systemBackground

        addSubview(textView)
        addSubview(sendButton)

        // Constraints for textView - grow upward by anchoring to bottom
        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 36)
        textViewHeightConstraint.priority = UILayoutPriority(999) // Allow constraint to be adjusted

        // Text view grows upward - anchor to bottom, allow top to move up
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            textView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
            textViewHeightConstraint,
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36) // Minimum height
        ])

        // Constraints for sendButton - align to textView bottom (iMessage size)
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            sendButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12) // Ensure button is visible
        ])

        // Ensure container has minimum height and can grow
        containerHeightConstraint = heightAnchor.constraint(equalToConstant: 60)
        containerHeightConstraint.priority = UILayoutPriority(999)
        containerHeightConstraint.isActive = true

        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        // Add placeholder label
        placeholderLabel = UILabel()
        placeholderLabel.text = "Journal entry..."
        placeholderLabel.textColor = UIColor.placeholderText
        placeholderLabel.font = UIFont.systemFont(ofSize: 17)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        // Placeholder aligned to text view's top (which moves up as text grows)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -12)
        ])

        // Show/hide placeholder based on text
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )

        // Set initial container height
        containerHeightConstraint.constant = 60

        // Update placeholder and send button after setup
        // Note: Text will be set in makeUIView, so placeholder will update there
        updatePlaceholder()
        updateSendButton()

        // Auto-focus
        DispatchQueue.main.async {
            self.textView.becomeFirstResponder()
        }
    }

    @objc func textDidChange() {
        updatePlaceholder()

        // Update height
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        let minHeight: CGFloat = 36
        let maxHeight: CGFloat = 90 // ~3 lines max, then scroll
        let newTextViewHeight = max(minHeight, min(estimatedSize.height, maxHeight))

        textViewHeightConstraint.constant = newTextViewHeight

        // Update container height to match text view height + padding
        let newContainerHeight = newTextViewHeight + 24 // 12 top + 12 bottom padding
        containerHeightConstraint.constant = max(60, newContainerHeight)

        // Enable scrolling if content exceeds max height
        textView.isScrollEnabled = estimatedSize.height > maxHeight

        // Invalidate intrinsic content size
        invalidateIntrinsicContentSize()

        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }

    func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func updateSendButton() {
        let isEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = !isEmpty
        sendButton.tintColor = isEmpty ? UIColor.systemGray3 : UIColor(accentColor)
    }

    @objc private func sendButtonTapped() {
        onSave?()
    }
}


#Preview {
    FocusView(focusStore: FocusStore())
}
