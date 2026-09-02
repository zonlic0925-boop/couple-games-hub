import SwiftUI

public struct SyncMindGameView: View {
    @State private var currentIndex = 0
    @State private var hostChoice: String? = nil
    @State private var guestChoice: String? = nil
    @State private var isRevealed = false
    @State private var matchScore = 0
    
    let questions = TacitQuestionBank.sampleQuestions
    var onExit: () -> Void
    
    public init(onExit: @escaping () -> Void) {
        self.onExit = onExit
    }
    
    private var currentQuestion: TacitQuestion {
        questions[currentIndex % questions.count]
    }
    
    public var body: some View {
        ZStack {
            CoupleColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 顶部状态栏
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(CoupleColors.textDark.opacity(0.6))
                    }
                    Spacer()
                    Text("默契积分: \(matchScore)")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.7)))
                }
                .padding(.horizontal)
                
                // 题目卡片
                VStack(spacing: 12) {
                    Text("第 \(currentIndex + 1) 题 / 共 \(questions.count) 题")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(CoupleColors.pinkMain)
                    
                    Text(currentQuestion.prompt)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(CoupleColors.textDark)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
                )
                .padding(.horizontal)
                
                // 选项选择区
                VStack(spacing: 16) {
                    optionButton(
                        text: currentQuestion.optionA,
                        isSelectedByHost: hostChoice == "A",
                        isSelectedByGuest: guestChoice == "A",
                        onHostSelect: { selectOption("A", isHost: true) },
                        onGuestSelect: { selectOption("A", isHost: false) }
                    )
                    
                    optionButton(
                        text: currentQuestion.optionB,
                        isSelectedByHost: hostChoice == "B",
                        isSelectedByGuest: guestChoice == "B",
                        onHostSelect: { selectOption("B", isHost: true) },
                        onGuestSelect: { selectOption("B", isHost: false) }
                    )
                }
                .padding(.horizontal)
                
                // 揭晓与惩罚区域
                if isRevealed {
                    VStack(spacing: 8) {
                        if hostChoice == guestChoice {
                            Text("🎉 心有灵犀！默契达成！")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("💔 意见不一！触发情侣小惩罚：")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(CoupleColors.pinkMain)
                            Text(currentQuestion.penalty)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CoupleColors.textDark)
                        }
                        
                        Button(action: nextQuestion) {
                            Text("下一题 →")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(CoupleColors.primaryGradient))
                        }
                        .padding(.top, 6)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.95))
                            .shadow(radius: 8)
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
    }
    
    private func optionButton(
        text: String,
        isSelectedByHost: Bool,
        isSelectedByGuest: Bool,
        onHostSelect: @escaping () -> Void,
        onGuestSelect: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(CoupleColors.textDark)
            
            HStack(spacing: 12) {
                Button(action: onHostSelect) {
                    Text(isSelectedByHost ? "💖 粉方已选" : "粉方选择")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelectedByHost ? CoupleColors.pinkMain : Color.white)
                        )
                        .foregroundColor(isSelectedByHost ? .white : CoupleColors.pinkMain)
                        .overlay(Capsule().stroke(CoupleColors.pinkMain, lineWidth: 1))
                }
                
                Button(action: onGuestSelect) {
                    Text(isSelectedByGuest ? "💙 蓝方已选" : "蓝方选择")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelectedByGuest ? CoupleColors.blueMain : Color.white)
                        )
                        .foregroundColor(isSelectedByGuest ? .white : CoupleColors.blueMain)
                        .overlay(Capsule().stroke(CoupleColors.blueMain, lineWidth: 1))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
        )
    }
    
    private func selectOption(_ opt: String, isHost: Bool) {
        if isHost {
            hostChoice = opt
        } else {
            guestChoice = opt
        }
        
        if hostChoice != nil && guestChoice != nil {
            isRevealed = true
            if hostChoice == guestChoice {
                matchScore += 10
            }
        }
    }
    
    private func nextQuestion() {
        hostChoice = nil
        guestChoice = nil
        isRevealed = false
        currentIndex = (currentIndex + 1) % questions.count
    }
}
