import Foundation
import Combine

struct AppPet: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var species: String
    var breed: String
    var birthday: Date
    var weight: Double
    var color: String
    var notes: String
    var createdAt: Date
    var map: String = ""

    init(
        id: UUID = UUID(),
        name: String,
        species: String,
        breed: String,
        birthday: Date,
        weight: Double,
        color: String,
        notes: String = "",
        createdAt: Date = Date(),
        map: String = ""
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.birthday = birthday
        self.weight = weight
        self.color = color
        self.notes = notes
        self.createdAt = createdAt
        self.map = map
    }
}

struct AppVaccineRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var petID: UUID
    var vaccineName: String
    var manufacturer: String
    var batchNumber: String
    var vaccinationDate: Date
    var nextDueDate: Date
    var veterinarian: String
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID,
        vaccineName: String,
        manufacturer: String,
        batchNumber: String,
        vaccinationDate: Date,
        nextDueDate: Date,
        veterinarian: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.vaccineName = vaccineName
        self.manufacturer = manufacturer
        self.batchNumber = batchNumber
        self.vaccinationDate = vaccinationDate
        self.nextDueDate = nextDueDate
        self.veterinarian = veterinarian
        self.notes = notes
        self.createdAt = createdAt
    }
}

struct AppReminder: Identifiable, Hashable {
    let id: UUID
    let petID: UUID
    let petName: String
    let vaccineName: String
    let dueDate: Date
    let daysRemaining: Int
}

struct AppPersistedData: Codable {
    var pets: [AppPet]
    var vaccineRecords: [AppVaccineRecord]
}

enum DemoSeed {
    static var didApplyDemoData = false

    static func apply() {
        guard CommandLine.arguments.contains("-demoData"), !didApplyDemoData else { return }
        apply(into: AppStore.shared)
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData"), !didApplyDemoData else { return }
        didApplyDemoData = true

        let now = Date()
        let calendar = Calendar.current
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: now) ?? now
        }

        let pet1 = UUID()
        let pet2 = UUID()
        let pet3 = UUID()
        let pet4 = UUID()
        let pet5 = UUID()
        let pet6 = UUID()
        let pet7 = UUID()
        let pet8 = UUID()

        let pets: [AppPet] = [
            AppPet(id: pet1, name: "毛毛", species: "狗", breed: "金毛寻回犬", birthday: day(-1095), weight: 32.5, color: "金色", notes: "活泼亲人，喜欢游泳", createdAt: now, map: ""),
            AppPet(id: pet2, name: "豆豆", species: "狗", breed: "柯基", birthday: day(-730), weight: 12.0, color: "黄白", notes: "小短腿，爱吃零食", createdAt: now, map: ""),
            AppPet(id: pet3, name: "咪咪", species: "猫", breed: "英国短毛猫", birthday: day(-1460), weight: 4.5, color: "蓝灰色", notes: "安静，喜欢晒太阳", createdAt: now, map: ""),
            AppPet(id: pet4, name: "旺财", species: "狗", breed: "中华田园犬", birthday: day(-1825), weight: 18.0, color: "黄色", notes: "看家能手，忠诚", createdAt: now, map: ""),
            AppPet(id: pet5, name: "雪球", species: "猫", breed: "布偶猫", birthday: day(-365), weight: 5.2, color: "白色", notes: "粘人，会撒娇", createdAt: now, map: ""),
            AppPet(id: pet6, name: "皮皮", species: "兔子", breed: "垂耳兔", birthday: day(-730), weight: 2.1, color: "灰白", notes: "好奇心重，喜欢啃胡萝卜", createdAt: now, map: ""),
            AppPet(id: pet7, name: "果冻", species: "猫", breed: "美国短毛猫", birthday: day(-1095), weight: 4.8, color: "银虎斑", notes: "好动，喜欢逗猫棒", createdAt: now, map: ""),
            AppPet(id: pet8, name: "布丁", species: "狗", breed: "泰迪", birthday: day(-2190), weight: 6.0, color: "棕色", notes: "聪明，会握手", createdAt: now, map: "")
        ]

        let vaccineRecords: [AppVaccineRecord] = [
            AppVaccineRecord(id: UUID(), petID: pet1, vaccineName: "狂犬病疫苗", manufacturer: "硕腾", batchNumber: "R20250101", vaccinationDate: day(-15), nextDueDate: day(350), veterinarian: "王医生", notes: "注射后观察30分钟", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet1, vaccineName: "犬瘟热疫苗", manufacturer: "英特威", batchNumber: "D20241201", vaccinationDate: day(-120), nextDueDate: day(245), veterinarian: "王医生", notes: "下次接种前一周会提醒", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet2, vaccineName: "狂犬病疫苗", manufacturer: "硕腾", batchNumber: "R20250115", vaccinationDate: day(-30), nextDueDate: day(335), veterinarian: "李医生", notes: "", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet2, vaccineName: "犬细小病毒疫苗", manufacturer: "英特威", batchNumber: "P20241120", vaccinationDate: day(-80), nextDueDate: day(285), veterinarian: "李医生", notes: "食欲正常", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet3, vaccineName: "猫三联", manufacturer: "勃林格", batchNumber: "F20250210", vaccinationDate: day(-45), nextDueDate: day(320), veterinarian: "周医生", notes: "首次免疫完成", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet3, vaccineName: "狂犬病疫苗", manufacturer: "硕腾", batchNumber: "R20250120", vaccinationDate: day(-20), nextDueDate: day(345), veterinarian: "周医生", notes: "", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet4, vaccineName: "狂犬病疫苗", manufacturer: "硕腾", batchNumber: "R20250201", vaccinationDate: day(-60), nextDueDate: day(305), veterinarian: "王医生", notes: "", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet5, vaccineName: "猫三联", manufacturer: "勃林格", batchNumber: "F20250301", vaccinationDate: day(-10), nextDueDate: day(355), veterinarian: "周医生", notes: "接种顺利", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet5, vaccineName: "猫白血病疫苗", manufacturer: "辉瑞", batchNumber: "L20250130", vaccinationDate: day(-5), nextDueDate: day(360), veterinarian: "周医生", notes: "建议每年加强", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet6, vaccineName: "兔瘟疫苗", manufacturer: "国产", batchNumber: "R20250220", vaccinationDate: day(-90), nextDueDate: day(-10), veterinarian: "吴医生", notes: "已过期，需要尽快补种", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet7, vaccineName: "猫三联", manufacturer: "勃林格", batchNumber: "F20250105", vaccinationDate: day(-35), nextDueDate: day(330), veterinarian: "郑医生", notes: "", createdAt: now),
            AppVaccineRecord(id: UUID(), petID: pet8, vaccineName: "犬腺病毒疫苗", manufacturer: "英特威", batchNumber: "A20241215", vaccinationDate: day(-70), nextDueDate: day(295), veterinarian: "王医生", notes: "小型犬注意剂量", createdAt: now)
        ]

        store.pets = pets
        store.vaccineRecords = vaccineRecords
        store.save()
    }
}

final class AppStore: ObservableObject {
    @Published var pets: [AppPet] = []
    @Published var vaccineRecords: [AppVaccineRecord] = []

    static let shared = AppStore()

    private let fileName = "AppPetVaxBook.json"

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") && !DemoSeed.didApplyDemoData {
            DemoSeed.apply()
        }
    }

    var reminders: [AppReminder] {
        let now = Date()
        let calendar = Calendar.current
        return vaccineRecords.map { record in
            let petName = pets.first(where: { $0.id == record.petID })?.name ?? "未知宠物"
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: now),
                to: calendar.startOfDay(for: record.nextDueDate)
            ).day ?? 0
            return AppReminder(
                id: record.id,
                petID: record.petID,
                petName: petName,
                vaccineName: record.vaccineName,
                dueDate: record.nextDueDate,
                daysRemaining: days
            )
        }
        .sorted { $0.dueDate < $1.dueDate }
    }

    func addPet(_ pet: AppPet) {
        pets.append(pet)
        save()
    }

    func updatePet(_ pet: AppPet) {
        if let index = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[index] = pet
            save()
        }
    }

    func deletePet(_ id: UUID) {
        pets.removeAll { $0.id == id }
        vaccineRecords.removeAll { $0.petID == id }
        save()
    }

    func addVaccineRecord(_ record: AppVaccineRecord) {
        vaccineRecords.append(record)
        save()
    }

    func updateVaccineRecord(_ record: AppVaccineRecord) {
        if let index = vaccineRecords.firstIndex(where: { $0.id == record.id }) {
            vaccineRecords[index] = record
            save()
        }
    }

    func deleteVaccineRecord(_ id: UUID) {
        vaccineRecords.removeAll { $0.id == id }
        save()
    }

    func save() {
        let persisted = AppPersistedData(pets: pets, vaccineRecords: vaccineRecords)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(persisted)
            try data.write(to: fileURL())
        } catch {
            return
        }
    }

    private func load() {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: url)
            let persisted = try decoder.decode(AppPersistedData.self, from: data)
            pets = persisted.pets
            vaccineRecords = persisted.vaccineRecords
        } catch {
            return
        }
    }

    private func fileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(fileName)
    }
}