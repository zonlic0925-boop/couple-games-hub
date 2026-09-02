import SwiftUI

public struct TacitQuestion: Identifiable, Codable {
    public let id: Int
    public let prompt: String
    public let optionA: String
    public let optionB: String
    public let penalty: String
    
    public init(id: Int, prompt: String, optionA: String, optionB: String, penalty: String) {
        self.id = id
        self.prompt = prompt
        self.optionA = optionA
        self.optionB = optionB
        self.penalty = penalty
    }
}

public struct TacitQuestionBank {
    public static let sampleQuestions: [TacitQuestion] = [
        TacitQuestion(
            id: 1,
            prompt: "周末休息，更倾向于怎么过？",
            optionA: "🛋️ 窝在沙发看剧点外卖",
            optionB: "☕ 出门探店看展逛街",
            penalty: "罚背着对方在客厅走一圈！"
        ),
        TacitQuestion(
            id: 2,
            prompt: "旅行途中突然下暴雨，会怎样？",
            optionA: "☔ 随遇而安找家咖啡馆发呆",
            optionB: "🗺️ 无论如何按原计划打卡",
            penalty: "给对方剥一个水果或揉肩 2 分钟！"
        ),
        TacitQuestion(
            id: 3,
            prompt: "如果突然中了一千万，第一件事是？",
            optionA: "✈️ 立刻买机票去环球旅行",
            optionB: "🏦 存银行收利息慢慢躺平",
            penalty: "深情对视 30 秒不许眨眼！"
        ),
        TacitQuestion(
            id: 4,
            prompt: "深夜肚子饿了，会选择？",
            optionA: "🍢 叫上一大堆烧烤小龙虾",
            optionB: "🥛 喝杯热牛奶忍忍睡觉",
            penalty: "用可爱的语气说‘我最听你话了’！"
        )
    ]
}
