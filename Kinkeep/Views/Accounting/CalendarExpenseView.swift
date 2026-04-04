import SwiftUI
import Charts

struct CalendarExpenseView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var lifestyleManager: LifestyleManager
    
    @State private var selectedDate = Date()
    @State private var isShowingAddExpense = false
    @State private var isShowingSettings = false
    @State private var isShowingInvoice = false
    
    // 計算邏輯搬移到 Computed Property
    var expensesForSelectedDate: [Expense] {
        vm.expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var totalAmount: Double {
        expensesForSelectedDate.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 生活型態標籤
                if !lifestyleManager.selectedTags.isEmpty {
                    lifestyleHeader
                }
                
                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding()
                    .background(Color(UIColor.systemBackground)).cornerRadius(10).padding()
                
                Divider()
                
                expenseList
            }
            .background(Color.themeBackground)
            .navigationTitle("月曆記帳")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { isShowingSettings = true } label: { Image(systemName: "gearshape.fill") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 15) {
                        Button { isShowingInvoice = true } label: { Image(systemName: "qrcode.viewfinder").symbolRenderingMode(.hierarchical) }
                        Button { isShowingAddExpense = true } label: { Image(systemName: "plus.circle.fill") }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddExpense) {
                AddExpenseView(selectedDate: selectedDate)
            }
            // ... 其他 sheet 實作 ...
        }
    }
    
    // 子視圖抽離，讓 body 保持乾淨
    private var lifestyleHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(lifestyleManager.selectedTags), id: \.self) { tag in
                    Label(tag.rawValue, systemImage: tag.icon)
                        .font(.caption).padding(6).background(tag.color.opacity(0.1))
                        .foregroundColor(tag.color).cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }.padding(.top, 5)
    }

    private var expenseList: some View {
        List {
            Section(header: HStack {
                Text("\(selectedDate, style: .date) 支出"); Spacer(); Text("$\(Int(totalAmount))").foregroundStyle(.red)
            }) {
                if expensesForSelectedDate.isEmpty {
                    Text("無記錄").foregroundStyle(.secondary)
                } else {
                    ForEach(expensesForSelectedDate) { expense in
                        ExpenseRow(expense: expense)
                    }
                    .onDelete { indexSet in
                        // 直接呼叫 vm 的刪除邏輯 (需在 AppViewModel 實作對應方法)
                        let ids = indexSet.map { expensesForSelectedDate[$0].id }
                        vm.expenses.removeAll { ids.contains($0.id) }
                        vm.saveAllData()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.themeBackground)
    }
}

// 內部使用的小元件
struct ExpenseRow: View {
    @EnvironmentObject var vm: AppViewModel
    let expense: Expense
    
    var body: some View {
        HStack {
            if let member = vm.members.first(where: { $0.id == expense.memberId }) {
                Text(member.role.icon).font(.title2).frame(width: 30)
            } else {
                Image(systemName: "cart.circle").font(.title2).foregroundColor(.gray).frame(width: 30)
            }
            VStack(alignment: .leading) {
                Text(expense.subCategory).font(.headline)
                HStack {
                    Text(expense.mainCategory).font(.caption).padding(4).background(Color.indigo.opacity(0.1)).cornerRadius(4)
                    if !expense.note.isEmpty { Text(expense.note).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Spacer(); Text("$\(Int(expense.amount))")
        }
    }
}
