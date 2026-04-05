//
//  AddGeneralTransactionView.swift
//  KinKeep
//

import SwiftUI

/// 新增日常交易視圖（含類別、發票載具）
struct AddGeneralTransactionView: View {
    @Binding var generalTransactions: [GeneralTransaction]
    let members: [Member]
    var saveAction: () -> Void
    let initialDate: Date

    @Environment(\.dismiss) var dismiss
    @StateObject private var categoryManager = CategoryManager.shared

    @State private var amountInput: String = ""
    @State private var transactionDate: Date
    @State private var selectedMember: Member?
    @State private var description: String = ""
    @State private var transactionType: GeneralTransaction.TransactionType = .expense

    // 🆕 類別
    @State private var selectedCategory: String = TransactionCategory.expenseCategories.first ?? "📋 其他"
    @State private var isAddingCustomCategory = false
    @State private var newCategoryInput: String = ""

    // 🆕 發票
    @State private var carrierCode: String = ""
    @State private var invoiceImageData: Data? = nil

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

    var currentCategories: [String] {
        transactionType == .expense
            ? categoryManager.allExpenseCategories
            : categoryManager.allIncomeCategories
    }

    var isSaveDisabled: Bool {
        amountInput.isEmpty || selectedMember == nil
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: 收支類型
                Section {
                    Picker("類型", selection: $transactionType) {
                        Text("💸 支出").tag(GeneralTransaction.TransactionType.expense)
                        Text("💰 收入").tag(GeneralTransaction.TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) { _, newType in
                        // 切換類型時重設類別
                        selectedCategory = newType == .expense
                            ? (categoryManager.allExpenseCategories.first ?? "📋 其他")
                            : (categoryManager.allIncomeCategories.first ?? "📋 其他")
                    }
                }

                // MARK: 基本資訊
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
                        Text("⚠️ 請先在「成員管理」新增成員").foregroundColor(.orange)
                    }

                    HStack {
                        Text(transactionType == .expense ? "💸 支出金額" : "💰 收入金額")
                        Spacer()
                        TextField("金額", text: $amountInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(transactionType == .expense ? .red : .green)
                    }
                }

                // MARK: 🆕 類別選擇
                Section("類別") {
                    // 類別捲動選擇
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(currentCategories, id: \.self) { category in
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategory == category
                                            ? (transactionType == .expense ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                            : Color.gray.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedCategory == category
                                            ? (transactionType == .expense ? .red : .green)
                                            : .primary
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedCategory == category
                                                    ? (transactionType == .expense ? Color.red : Color.green)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                    .onTapGesture { selectedCategory = category }
                            }

                            // 新增自訂類別按鈕
                            Button {
                                isAddingCustomCategory = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("自訂")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.indigo.opacity(0.1))
                                .foregroundColor(.indigo)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                    // 已選類別顯示
                    HStack {
                        Text("已選：")
                            .font(.caption).foregroundColor(.secondary)
                        Text(selectedCategory)
                            .font(.caption).fontWeight(.medium)
                    }
                }

                // MARK: 說明備註
                Section("說明／備註 (選填)") {
                    TextEditor(text: $description)
                        .frame(height: 80)
                        .overlay(
                            Text(description.isEmpty ? "輸入說明或備註..." : "")
                                .foregroundColor(.secondary)
                                .allowsHitTesting(false)
                                .padding(.top, 8).padding(.leading, 5),
                            alignment: .topLeading
                        )
                }

                // MARK: 🆕 雲端發票載具
                InvoiceSection(carrierCode: $carrierCode, invoiceImageData: $invoiceImageData)

                // MARK: 儲存
                Button("儲存交易記錄") {
                    saveTransaction()
                }
                .disabled(isSaveDisabled)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle(transactionType == .expense ? "新增支出" : "新增收入")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            // 自訂類別 Alert
            .alert("新增自訂類別", isPresented: $isAddingCustomCategory) {
                TextField("輸入類別名稱（含 Emoji）", text: $newCategoryInput)
                Button("新增") {
                    if transactionType == .expense {
                        categoryManager.addExpenseCategory(newCategoryInput)
                    } else {
                        categoryManager.addIncomeCategory(newCategoryInput)
                    }
                    if !newCategoryInput.isEmpty {
                        selectedCategory = newCategoryInput
                    }
                    newCategoryInput = ""
                }
                Button("取消", role: .cancel) { newCategoryInput = "" }
            } message: {
                Text("建議格式：🏷 類別名稱")
            }
        }
    }

    func saveTransaction() {
        guard let member = selectedMember,
              let parsedAmount = Double(amountInput.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return }

        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCarrier = carrierCode.trimmingCharacters(in: .whitespacesAndNewlines)

        let newTransaction = GeneralTransaction(
            date: transactionDate,
            memberName: member.name,
            amount: parsedAmount,
            description: trimmedDesc.isEmpty
                ? (transactionType == .expense ? "一般支出" : "一般收入")
                : trimmedDesc,
            type: transactionType,
            category: selectedCategory,
            invoiceCarrier: trimmedCarrier.isEmpty ? nil : trimmedCarrier,
            invoiceImageData: invoiceImageData
        )

        generalTransactions.append(newTransaction)
        saveAction()
        dismiss()
    }
}

