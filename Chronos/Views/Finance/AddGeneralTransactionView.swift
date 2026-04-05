//
//  AddGeneralTransactionView.swift
//  KinKeep
//

internal import SwiftUI

/// 新增日常交易視圖（含生活型態類別、發票載具）
struct AddGeneralTransactionView: View {
    @Binding var generalTransactions: [GeneralTransaction]
    let members: [Member]
    var saveAction: () -> Void
    let initialDate: Date

    @Environment(\.dismiss) var dismiss
    @StateObject private var lifestyleManager = LifestyleManager.shared

    @State private var amountInput: String = ""
    @State private var transactionDate: Date
    @State private var description: String = ""
    @State private var transactionType: GeneralTransaction.TransactionType = .expense

    // 用 UUID 追蹤選中的成員（避免 Binding self immutable 問題）
    @State private var selectedMemberID: UUID?

    // 二層類別
    @State private var selectedMainCategory: String = ""
    @State private var selectedSubCategory: String = ""

    // 發票
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
        self._selectedMemberID = State(initialValue: members.first?.id)
    }

    // 目前選中的成員
    var selectedMember: Member? {
        members.first(where: { $0.id == selectedMemberID })
    }

    // 主類別列表
    var mainCategories: [String] {
        transactionType == .expense
            ? LifestyleManager.shared.mainCategories
            : LifestyleManager.shared.incomeCategories
    }

    // 子類別列表
    var subCategories: [String] {
        transactionType == .expense
            ? lifestyleManager.getSubCategories(for: selectedMainCategory)
            : []
    }

    // 最終類別字串
    var finalCategory: String {
        if transactionType == .income { return selectedMainCategory }
        return selectedSubCategory.isEmpty
            ? selectedMainCategory
            : "\(selectedMainCategory) · \(selectedSubCategory)"
    }

    var isSaveDisabled: Bool {
        amountInput.isEmpty || selectedMember == nil || selectedMainCategory.isEmpty
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
                    .onChange(of: transactionType) { _, _ in
                        selectedMainCategory = mainCategories.first ?? ""
                        selectedSubCategory = lifestyleManager.getSubCategories(for: selectedMainCategory).first ?? ""
                    }
                }

                // MARK: 基本資訊
                Section("基本資訊") {
                    DatePicker("日期與時間", selection: $transactionDate,
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

                    if !members.isEmpty {
                        // 用 UUID 做 Picker，避免 self immutable 問題
                        Picker("歸屬成員", selection: $selectedMemberID) {
                            ForEach(members) { member in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: member.colorHex))
                                        .frame(width: 10, height: 10)
                                    Text(member.name)
                                }
                                .tag(member.id as UUID?)
                            }
                        }
                    } else {
                        Text("⚠️ 請先在「成員管理」新增成員")
                            .foregroundColor(.orange)
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

                // MARK: 主類別選擇
                Section(transactionType == .expense ? "支出主類別" : "收入類別") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(mainCategories, id: \.self) { cat in
                                Text(cat)
                                    .font(.subheadline).fontWeight(.medium)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(
                                        selectedMainCategory == cat
                                            ? (transactionType == .expense
                                               ? Color.red.opacity(0.15)
                                               : Color.green.opacity(0.15))
                                            : Color.gray.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedMainCategory == cat
                                            ? (transactionType == .expense ? .red : .green)
                                            : .primary
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedMainCategory == cat
                                                    ? (transactionType == .expense ? Color.red : Color.green)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                    .onTapGesture {
                                        selectedMainCategory = cat
                                        selectedSubCategory = lifestyleManager.getSubCategories(for: cat).first ?? ""
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                // MARK: 子類別選擇（僅支出有）
                if transactionType == .expense && !subCategories.isEmpty {
                    Section("支出子類別") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(subCategories, id: \.self) { sub in
                                    Text(sub)
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(
                                            selectedSubCategory == sub
                                                ? Color.indigo.opacity(0.15)
                                                : Color.gray.opacity(0.1)
                                        )
                                        .foregroundColor(selectedSubCategory == sub ? .indigo : .secondary)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    selectedSubCategory == sub ? Color.indigo : Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                        .onTapGesture { selectedSubCategory = sub }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                        if !selectedSubCategory.isEmpty {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.indigo).font(.caption)
                                Text("\(selectedMainCategory) · \(selectedSubCategory)")
                                    .font(.caption).foregroundColor(.indigo)
                            }
                        }
                    }
                }

                // MARK: 說明備註
                Section("說明／備註 (選填)") {
                    TextEditor(text: $description)
                        .frame(height: 70)
                        .overlay(
                            Text(description.isEmpty ? "輸入說明或備註..." : "")
                                .foregroundColor(.secondary)
                                .allowsHitTesting(false)
                                .padding(.top, 8).padding(.leading, 5),
                            alignment: .topLeading
                        )
                }

                // MARK: 雲端發票載具
                InvoiceSection(carrierCode: $carrierCode, invoiceImageData: $invoiceImageData)

                // MARK: 儲存
                Button("儲存交易記錄") { saveTransaction() }
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
            .onAppear {
                if selectedMainCategory.isEmpty {
                    selectedMainCategory = mainCategories.first ?? ""
                    selectedSubCategory = lifestyleManager.getSubCategories(for: selectedMainCategory).first ?? ""
                }
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
                ? (transactionType == .expense ? finalCategory : "一般收入")
                : trimmedDesc,
            type: transactionType,
            category: finalCategory,
            invoiceCarrier: trimmedCarrier.isEmpty ? nil : trimmedCarrier,
            invoiceImageData: invoiceImageData
        )

        generalTransactions.append(newTransaction)
        saveAction()
        dismiss()
    }
}

