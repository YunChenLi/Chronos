//
//  AddGeneralTransactionView.swift
//  Chronos
//

import SwiftUI

/// 新增日常交易視圖
struct AddGeneralTransactionView: View {
    @Binding var generalTransactions: [GeneralTransaction]
    let members: [Member]
    var saveAction: () -> Void
    let initialDate: Date

    @Environment(\.dismiss) var dismiss

    @State private var amountInput: String = ""
    @State private var transactionDate: Date
    @State private var selectedMember: Member?
    @State private var description: String = ""
    @State private var transactionType: GeneralTransaction.TransactionType = .expense

    init(
        generalTransactions: Binding<[GeneralTransaction]>,
        members: [Member],
        saveAction: @escaping () -> Void,
        initialDate: Date
    ) {
        self._generalTransactions = generalTransactions
        self.members = members
        self.saveAction = saveAction
        self.initialDate = initialDate
        self._transactionDate = State(initialValue: initialDate)
        self._selectedMember = State(initialValue: members.first)
    }

    var isSaveButtonDisabled: Bool {
        amountInput.isEmpty || selectedMember == nil
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("類型", selection: $transactionType) {
                    Text("支出 (Expense)").tag(GeneralTransaction.TransactionType.expense)
                    Text("收入 (Income)").tag(GeneralTransaction.TransactionType.income)
                }
                .pickerStyle(.segmented)

                Section("基本資訊") {
                    DatePicker("日期與時間", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

                    if !members.isEmpty {
                        Picker("歸屬成員", selection: $selectedMember) {
                            ForEach(members, id: \.self) { member in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: member.colorHex))
                                        .frame(width: 10, height: 10)
                                    Text(member.name)
                                }
                                .tag(Optional(member))
                            }
                        }
                    } else {
                        Text("⚠️ 請先在「成員管理」頁面新增家庭成員")
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text(transactionType == .expense ? "支出金額" : "收入金額")
                        Spacer()
                        TextField("金額", text: $amountInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(transactionType == .expense ? .red : .green)
                    }
                }

                Section("說明/備註 (選填)") {
                    TextEditor(text: $description)
                        .frame(height: 80)
                }

                Button("儲存交易記錄") {
                    saveTransaction()
                }
                .disabled(isSaveButtonDisabled)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle(transactionType == .expense ? "新增日常支出" : "新增日常收入")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    func saveTransaction() {
        guard let member = selectedMember,
              let parsedAmount = Double(amountInput.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return }

        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)

        let newTransaction = GeneralTransaction(
            date: transactionDate,
            memberName: member.name,
            amount: parsedAmount,
            description: trimmedDesc.isEmpty
                ? (transactionType == .expense ? "一般支出" : "一般收入")
                : trimmedDesc,
            type: transactionType
        )

        generalTransactions.append(newTransaction)
        saveAction()
        dismiss()
    }
}
