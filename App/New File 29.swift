import SwiftUI

private enum PlanStage {
    case calendar
    case tasks
    case launch
    case active
}

struct PlanView: View {
    let plan: AIPlan
    private let onStartNewPlan: (() -> Void)?
    
    @StateObject private var progressStore = PlanProgressStore()
    @State private var stage: PlanStage
    @State private var monthOffset = 0
    @State private var selectedDayDate: String?
    @State private var expandedTaskIDs: Set<String> = []
    
    private let calendar = Calendar.current
    
    init(
        plan: AIPlan,
        resumeAtActiveTasks: Bool = false,
        onStartNewPlan: (() -> Void)? = nil
    ) {
        self.plan = plan
        self.onStartNewPlan = onStartNewPlan
        _stage = State(
            initialValue: resumeAtActiveTasks ? .active : .calendar
        )
    }
    
    private var sortedDays: [AIPlanDay] {
        plan.days.sorted { $0.date < $1.date }
    }
    
    private var allTaskIDs: [String] {
        plan.days.flatMap { day in
            day.tasks.indices.map { taskKey(day: day, index: $0) }
        }
    }
    
    private var totalTaskCount: Int {
        allTaskIDs.count
    }
    
    private var completedTaskCount: Int {
        progressStore.completedCount(for: allTaskIDs)
    }
    
    private var progressFraction: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
    
    private var selectedDay: AIPlanDay? {
        guard let selectedDayDate else { return nil }
        return plan.days.first { $0.date == selectedDayDate }
    }
    
    private var displayedMonth: Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(
            byAdding: .month,
            value: monthOffset,
            to: today
        ) ?? today
    }
    
    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstIndex = max(
            0,
            min(calendar.firstWeekday - 1, symbols.count - 1)
        )
        
        return Array(symbols[firstIndex...]) +
        Array(symbols[..<firstIndex])
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            Group {
                switch stage {
                case .calendar:
                    calendarStage
                case .tasks:
                    tasksStage
                case .launch:
                    launchStage
                case .active:
                    activeStage
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            PlanPersistenceStore.savePlan(plan)
            
            if selectedDayDate == nil {
                selectedDayDate = sortedDays.first?.date
            }
        }
    }
    
    // MARK: - Calendar Stage
    
    private var calendarStage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(
                    eyebrow: "YOUR PERSONAL PLAN",
                    title: "Your journey, day by day.",
                    subtitle: "Explore your schedule and see what's ahead."
                )
                
                overviewCard
                calendarCard
                
                if let day = selectedDay {
                    selectedDayCard(day)
                }
                
                Button {
                    stage = .tasks
                } label: {
                    primaryButtonLabel("Explore Your Tasks")
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, 28)
        }
    }
    
    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.white)
                
                Text("YOUR GAME PLAN")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
            }
            
            Text(plan.overview)
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .overlay(.white.opacity(0.25))
            
            HStack(spacing: 18) {
                overviewMetric(
                    value: "\(plan.days.count)",
                    label: "Days"
                )
                
                overviewMetric(
                    value: "\(totalTaskCount)",
                    label: "Tasks"
                )
                
                overviewMetric(
                    value: "\(completedTaskCount)",
                    label: "Completed"
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.30, blue: 0.76),
                    Color(red: 0.34, green: 0.24, blue: 0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private func overviewMetric(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var calendarCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your calendar")
                        .font(.headline)
                    
                    Text(monthTitle(displayedMonth))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous month")
                
                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next month")
            }
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 7
                ),
                spacing: 10
            ) {
                ForEach(
                    orderedWeekdaySymbols.indices,
                    id: \.self
                ) { index in
                    Text(orderedWeekdaySymbols[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(
                    calendarCells().indices,
                    id: \.self
                ) { index in
                    calendarCell(at: index)
                }
            }
            
            HStack(spacing: 14) {
                legendDot(color: .blue, label: "Plan day")
                legendDot(color: .green, label: "Completed tasks")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private func calendarCell(at index: Int) -> some View {
        let cells = calendarCells()
        
        guard cells.indices.contains(index),
              let date = cells[index] else {
            return AnyView(
                Color.clear
                    .frame(height: 40)
            )
        }
        
        return AnyView(calendarDayCell(date))
    }
    
    private func calendarDayCell(_ date: Date) -> some View {
        let dateString = formatDate(date)
        let dayPlan = plan.days.first { $0.date == dateString }
        let isSelected = selectedDayDate == dateString
        
        let hasCompletedTask: Bool
        
        if let dayPlan {
            hasCompletedTask = dayPlan.tasks.indices.contains { index in
                progressStore.isCompleted(
                    taskKey(day: dayPlan, index: index)
                )
            }
        } else {
            hasCompletedTask = false
        }
        
        return Button {
            selectedDayDate = dateString
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(
                        .subheadline.weight(
                            isSelected ? .bold : .medium
                        )
                    )
                    .foregroundStyle(
                        isSelected ? .white : .primary
                    )
                
                Circle()
                    .fill(
                        hasCompletedTask
                        ? Color.green
                        : (dayPlan != nil ? Color.blue : Color.clear)
                    )
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                } else if dayPlan != nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            dayPlan == nil
            ? date.formatted(date: .complete, time: .omitted)
            : "Plan day, \(date.formatted(date: .complete, time: .omitted))"
        )
    }
    
    private func selectedDayCard(_ day: AIPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAY \(day.dayNumber)")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.blue)
                    
                    Text(day.focus)
                        .font(.title3.bold())
                }
                
                Spacer()
                
                Text("\(day.tasks.count) tasks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Text(displayDate(day.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if day.tasks.isEmpty {
                Text("No tasks are scheduled for this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(day.tasks.indices, id: \.self) { index in
                    compactTaskRow(
                        day.tasks[index],
                        key: taskKey(day: day, index: index)
                    )
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    // MARK: - Task Exploration Stage
    
    private var tasksStage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                backButton(title: "Back to calendar") {
                    stage = .calendar
                }
                
                header(
                    eyebrow: "THE DETAILS",
                    title: "Every task has a purpose.",
                    subtitle: "Explore what you'll do, how long it takes, and why it matters."
                )
                
                if !plan.strategy.isEmpty {
                    infoCard(
                        title: "Your strategy",
                        message: plan.strategy,
                        symbol: "target"
                    )
                }
                
                ForEach(sortedDays) { day in
                    taskExplorationDayCard(day)
                }
                
                Button {
                    stage = .launch
                } label: {
                    primaryButtonLabel("I'm Ready")
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, 28)
        }
    }
    
    private func taskExplorationDayCard(
        _ day: AIPlanDay
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DAY \(day.dayNumber)")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.blue)
                    
                    Text(day.focus)
                        .font(.title3.bold())
                }
                
                Spacer()
                
                Text(displayDate(day.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(day.tasks.indices, id: \.self) { index in
                taskCard(
                    day.tasks[index],
                    key: taskKey(day: day, index: index),
                    allowCompletion: false
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    // MARK: - Launch Stage
    
    private var launchStage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 30)
                
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.10))
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.14))
                        .frame(width: 112, height: 112)
                    
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 12) {
                    Text("YOUR NEXT CHAPTER")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.blue)
                    
                    Text("Your journey starts now.")
                        .font(
                            .system(
                                size: 36,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text(plan.closingMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    launchChecklistRow(
                        symbol: "calendar",
                        title: "Follow your schedule",
                        subtitle: "Work through your plan one day at a time."
                    )
                    
                    launchChecklistRow(
                        symbol: "checkmark.circle",
                        title: "Track your progress",
                        subtitle: "Mark tasks complete as you finish them."
                    )
                    
                    launchChecklistRow(
                        symbol: "arrow.clockwise",
                        title: "Stay flexible",
                        subtitle: "Adjust your approach when real life changes."
                    )
                }
                .padding(20)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                
                Button {
                    stage = .active
                } label: {
                    primaryButtonLabel("Get Started")
                }
                .buttonStyle(.plain)
                
                Button("Review tasks again") {
                    stage = .tasks
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                
                Spacer(minLength: 20)
            }
            .padding(22)
        }
    }
    
    // MARK: - Active Plan Stage
    
    private var activeStage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(
                    eyebrow: "YOUR PLAN IS IN MOTION",
                    title: "Keep showing up.",
                    subtitle: plan.motivationalMessage
                )
                
                progressCard
                
                if totalTaskCount > 0 &&
                    completedTaskCount == totalTaskCount {
                    infoCard(
                        title: "You did it!",
                        message: "You've completed every task in this plan. Take a moment to recognize the work you've put in.",
                        symbol: "trophy.fill"
                    )
                }
                
                ForEach(sortedDays) { day in
                    activeDayCard(day)
                }
                
                Button {
                    stage = .calendar
                } label: {
                    secondaryButtonLabel("Return to Calendar")
                }
                .buttonStyle(.plain)
                
                if let onStartNewPlan {
                    Button {
                        onStartNewPlan()
                    } label: {
                        secondaryButtonLabel("Create a New Plan")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .padding(.bottom, 28)
        }
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overall progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(progressFraction * 100))%")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: progressFraction)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
            
            Text("\(completedTaskCount) of \(totalTaskCount) tasks completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func activeDayCard(_ day: AIPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DAY \(day.dayNumber)")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.blue)
                    
                    Text(day.focus)
                        .font(.title3.bold())
                }
                
                Spacer()
                
                Text(displayDate(day.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(day.tasks.indices, id: \.self) { index in
                taskCard(
                    day.tasks[index],
                    key: taskKey(day: day, index: index),
                    allowCompletion: true
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    // MARK: - Task Cards
    
    private func compactTaskRow(
        _ task: AIPlanTask,
        key: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: task.visualKey))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(taskColor(for: task.visualKey))
                .frame(width: 38, height: 38)
                .background(taskColor(for: task.visualKey).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                
                HStack(spacing: 8) {
                    Text(task.category)
                    
                    if let minutes = task.durationMinutes {
                        Text("•")
                        Text(durationLabel(minutes))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if progressStore.isCompleted(key) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func taskCard(
        _ task: AIPlanTask,
        key: String,
        allowCompletion: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            taskCardHeader(
                task,
                key: key,
                allowCompletion: allowCompletion
            )
            
            if expandedTaskIDs.contains(key) {
                Divider()
                    .padding(.horizontal, 14)
                
                taskCardDetails(
                    task,
                    key: key,
                    allowCompletion: allowCompletion
                )
            }
        }
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    progressStore.isCompleted(key) && allowCompletion
                    ? Color.green.opacity(0.45)
                    : Color.clear,
                    lineWidth: 1.5
                )
        }
    }
    
    private func taskCardHeader(
        _ task: AIPlanTask,
        key: String,
        allowCompletion: Bool
    ) -> some View {
        let color = taskColor(for: task.visualKey)
        let isCompleted = progressStore.isCompleted(key)
        
        return HStack(alignment: .top, spacing: 12) {
            Button {
                toggleExpanded(key)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconName(for: task.visualKey))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(task.category)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(color)
                        
                        if let minutes = task.durationMinutes {
                            Label(
                                durationLabel(minutes),
                                systemImage: "clock"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    if !allowCompletion {
                        Image(
                            systemName: expandedTaskIDs.contains(key)
                            ? "chevron.up"
                            : "chevron.down"
                        )
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if allowCompletion {
                Button {
                    progressStore.toggle(key)
                } label: {
                    Image(
                        systemName: isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                    )
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isCompleted
                    ? "Mark task incomplete"
                    : "Mark task complete"
                )
            }
        }
        .padding(14)
    }
    
    private func taskCardDetails(
        _ task: AIPlanTask,
        key: String,
        allowCompletion: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if !task.description.isEmpty {
                taskDetailSection(
                    title: "WHAT YOU'LL DO",
                    text: task.description
                )
            }
            
            if !task.instructions.isEmpty {
                instructionsSection(
                    task.instructions,
                    visualKey: task.visualKey
                )
            }
            
            if !task.benefit.isEmpty {
                benefitSection(
                    task.benefit,
                    visualKey: task.visualKey
                )
            }
            
            if allowCompletion {
                completionButton(key)
            }
        }
        .padding(14)
    }
    
    private func instructionsSection(
        _ instructions: [String],
        visualKey: String
    ) -> some View {
        let color = taskColor(for: visualKey)
        
        return VStack(alignment: .leading, spacing: 9) {
            Text("STEP BY STEP")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            
            ForEach(instructions.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                        .frame(width: 24, height: 24)
                        .background(color.opacity(0.12))
                        .clipShape(Circle())
                    
                    Text(instructions[index])
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func benefitSection(
        _ benefit: String,
        visualKey: String
    ) -> some View {
        let color = taskColor(for: visualKey)
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("WHY IT MATTERS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            
            Text(benefit)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func completionButton(_ key: String) -> some View {
        let isCompleted = progressStore.isCompleted(key)
        
        return Button {
            progressStore.toggle(key)
        } label: {
            Label(
                isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                systemImage: isCompleted
                ? "arrow.uturn.backward.circle"
                : "checkmark.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isCompleted
                ? Color.gray.opacity(0.12)
                : Color.blue.opacity(0.12)
            )
            .foregroundStyle(
                isCompleted ? Color.secondary : Color.blue
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
    
    private func taskDetailSection(
        title: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Shared UI
    
    private func header(
        eyebrow: String,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func backButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
    }
    
    private func primaryButtonLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }
    
    private func secondaryButtonLabel(_ title: String) -> some View {
        HStack {
            Image(systemName: "calendar")
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(.blue)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func infoCard(
        title: String,
        message: String,
        symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func launchChecklistRow(
        symbol: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func legendDot(
        color: Color,
        label: String
    ) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Calendar Helpers
    
    private func calendarCells() -> [Date?] {
        guard
            let monthInterval = calendar.dateInterval(
                of: .month,
                for: displayedMonth
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: displayedMonth
            )
        else {
            return []
        }
        
        let firstWeekday = calendar.component(
            .weekday,
            from: monthInterval.start
        )
        
        let leadingSpaces = (
            firstWeekday - calendar.firstWeekday + 7
        ) % 7
        
        var cells: [Date?] = Array(
            repeating: nil,
            count: leadingSpaces
        )
        
        for day in dayRange {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: monthInterval.start
            ) {
                cells.append(date)
            }
        }
        
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        
        return cells
    }
    
    private func monthTitle(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: date)
    }
    
    private func displayDate(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else {
            return dateString
        }
        
        return date.formatted(
            .dateTime.weekday(.wide).month(.abbreviated).day()
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.date(from: dateString)
    }
    
    // MARK: - Task Helpers
    
    private func taskKey(
        day: AIPlanDay,
        index: Int
    ) -> String {
        "\(day.date)-\(index)"
    }
    
    private func toggleExpanded(_ key: String) {
        if expandedTaskIDs.contains(key) {
            expandedTaskIDs.remove(key)
        } else {
            expandedTaskIDs.insert(key)
        }
    }
    
    private func durationLabel(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if remainingMinutes == 0 {
            return "\(hours) hr"
        }
        
        return "\(hours) hr \(remainingMinutes) min"
    }
    
   
    private func iconName(for visualKey: String) -> String {
        switch visualKey.lowercased() {
        case "technical", "coding":
            return "laptopcomputer"
        case "fitness":
            return "figure.run"
        case "learning":
            return "book.closed.fill"
        case "research":
            return "magnifyingglass"
        case "practice":
            return "repeat"
        case "recovery":
            return "heart.fill"
        case "planning", "organization":
            return "calendar"
        case "creative", "design":
            return "paintpalette.fill"
        case "review":
            return "checkmark.seal.fill"
        case "writing":
            return "pencil.line"
        case "language":
            return "character.book.closed.fill"
        case "communication":
            return "bubble.left.and.bubble.right.fill"
        case "finance":
            return "chart.bar.fill"
        default:
            return "star.fill"
        }
    }

    private func taskColor(for visualKey: String) -> Color {
        switch visualKey.lowercased() {
        case "technical", "coding":
            return .blue
        case "fitness":
            return .orange
        case "learning", "language":
            return .purple
        case "research":
            return .indigo
        case "practice":
            return .teal
        case "recovery":
            return .green
        case "planning", "organization":
            return .cyan
        case "creative", "design":
            return .pink
        case "writing":
            return .orange
        case "communication":
            return .mint
        case "finance":
            return .brown
        case "review":
            return .mint
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        PlanView(plan: AIPlan.preview)
    }
}
