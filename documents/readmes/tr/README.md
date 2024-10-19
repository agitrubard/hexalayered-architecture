# 🏛️ HexaLayered Mimari

![](/documents/images/cover.jpg?raw=true)

## İçindekiler

1. [Özet](#özet)
2. [Mimari Genel Bakış](#mimari-genel-bakış)
3. [Katmanlar ve Sorumlulukları](#katmanlar-ve-sorumlulukları)
    - [Controller Katmanı](#1-controller-katmanı)
    - [Service Katmanı](#2-service-katmanı)
    - [Port/Adapter Katmanı](#3-portadapter-katmanı)
    - [Repository Katmanı](#4-repository-katmanı)
4. [İsimlendirme Kuralları](#isimlendirme-kuralları)
5. [Avantajlar ve Çözülen Problemler](#avantajlar-ve-çözülen-problemler)
6. [En İyi Uygulamalar](#en-iyi-uygulamalar)
7. [Modüler Yapı](#modüler-yapı)
8. [Katkıda Bulunma](#katkıda-bulunma)
9. [Lisans](#lisans)
10. [SSS](#sss)

## Özet

HexaLayered Mimari, Spring Boot uygulamaları için geliştirilmiş, Hexagonal (Ports and Adapters) ve Katmanlı mimarilerin
avantajlarını birleştiren yenilikçi bir mimari yaklaşımdır. Bu mimari, modülerlik ve basitliği bir araya getirerek
ölçeklenebilir ve sürdürülebilir uygulamalar geliştirmeyi amaçlar.

"HexaLayered" ismi, iki temel mimari yaklaşımın birleşimini yansıtır:

- **Hexa-**: Hexagonal Mimari'den gelir. Bu mimari, uygulamanın çekirdeğini dış dünyadan izole etmeyi ve bağımlılıkları
  yönetmeyi amaçlar.
- **-Layered**: Geleneksel Katmanlı Mimari'den esinlenilmiştir. Bu, uygulamayı belirli sorumlulukları olan katmanlara
  ayırma prensibine dayanır.

HexaLayered Mimari, modern Spring Boot uygulamaları için esnek, sürdürülebilir ve anlaşılır bir mimari çözüm sunar.

Bu mimari yaklaşım:

- Entity bağımlılığını azaltır
- Modülerliği artırır
- Domain-Driven Design prensiplerinin uygulanmasını kolaylaştırır
- Test edilebilirliği artırır
- Değişikliklerin etkisini sınırlar
- Kod organizasyonunu ve bakımını kolaylaştırır

Modüler port, adapter ve servis yapısı sayesinde, uygulamanın farklı bölümlerini bağımsız olarak geliştirme ve
değiştirme esnekliği sunar. Bu mimari, büyük ve karmaşık projelerde bile kodun organizasyonunu ve bakımını
kolaylaştırır, test edilebilirliği artırır ve uzun vadeli sürdürülebilirlik sağlar.

HexaLayered Mimari'yi kullanırken, yukarıda belirtilen en iyi uygulamaları takip etmek, mimarinin sağladığı
avantajlardan maksimum düzeyde faydalanmanızı sağlayacaktır. Her projenin kendine özgü gereksinimleri olabileceğini
unutmayın ve gerektiğinde bu mimariyi projenizin ihtiyaçlarına göre uyarlayın.

Bu mimari yaklaşım, yazılım geliştirme ekiplerine temiz, modüler ve sürdürülebilir kod yazma konusunda rehberlik eder.
Sonuç olarak, HexaLayered Mimari, modern yazılım geliştirme pratiklerini destekleyen, ölçeklenebilir ve dayanıklı
uygulamalar oluşturmanıza yardımcı olan güçlü bir mimari çözüm sunar.

---

## Mimari Genel Bakış

**HexaLayered Mimari dört ana katmandan oluşur.
Bu katmanlar birbirleriyle belirli arayüzler üzerinden iletişim kurar ve her birinin kendi sorumlulukları vardır.**

![hexalayered-architecture.png](/documents/architecture/hexalayered-architecture.png)

---

## Katmanlar ve Sorumlulukları

### 1. Controller Katmanı

**HTTP isteklerini karşılar, istek nesnelerini işler ve uygun yanıt nesnelerini döndürür.**

- **Paket**: `dev.agitrubard.hexalayered.[module].controller`
- **Girdi**: İstek Nesnesi | `TicketCreateRequest`
- **Çıktı**: Yanıt Nesnesi | `TicketResponse`
- **İletişim**: Service Katmanı ile doğrudan iletişim kurar.
- **Erişim Belirleyici**:
    - Controller sınıfları `package-private` olmalıdır

**Örnek:**

```java
package dev.agitrubard.hexalayered.ticket.controller;

@RestController
class TicketController {

    private final TicketCreateService ticketCreateService;

    TicketController(TicketCreateService ticketCreateService) {
        this.ticketCreateService = ticketCreateService;
    }

    @PostMapping("/api/v1/ticket")
    SuccessResponse<TicketResponse> create(@RequestBody TicketCreateRequest request) {
        Ticket ticket = ticketCreateService.createTicket(request);
        TicketResponse ticketResponse = TicketToResponseMapper.map(ticket);
        return SuccessResponse.of(ticket);
    }
}
```

### 2. Service Katmanı

**İş mantığını yürütür, gerekli doğrulamaları yapar ve domain nesneleri üzerinde işlemler gerçekleştirir.**

- **Paket**:
    - Arayüz: `dev.agitrubard.hexalayered.[module].service`
    - Uygulama: `dev.agitrubard.hexalayered.[module].service.impl`
- **Girdi**: İstek Nesnesi veya özel sarmalayıcı nesneler | `TicketCreateRequest` veya `Long` veya `String` vb.
- **Çıktı**: Domain Nesnesi veya özel sarmalayıcı nesneler | `Ticket` veya `Long` veya `String` vb.
- **İletişim**:
    - Service arayüzü Controller tarafından çağrılır.
    - ServiceImpl, Port arayüzlerini kullanarak Port/Adapter Katmanı ile iletişim kurar.
- **Erişim Belirleyici**:
    - Service arayüzleri `public` olmalıdır
    - Service uygulama sınıfları `package-private` olmalıdır

**Örnek:**

```java
package dev.agitrubard.hexalayered.ticket.service;

public interface TicketCreateService {
    Ticket create(TicketCreateRequest request);
}
```

```java
package dev.agitrubard.hexalayered.ticket.service.impl;

class TicketCreateServiceImpl implements TicketCreateService {

    private final TicketSavePort ticketSavePort;

    TicketCreateServiceImpl(TicketSavePort ticketSavePort) {
        this.ticketSavePort = ticketSavePort;
    }

    @Override
    public Ticket create(TicketCreateRequest request) {
        Ticket ticket = new Ticket(request.getTitle(), request.getDescription());
        return ticketSavePort.saveTicket(ticket);
    }
}
```

### 3. Port/Adapter Katmanı

**Dış sistemlerle iletişimi sağlar, domain nesnelerini dış sistemlerin anlayabileceği formatlara dönüştürür ve tam
tersini yapar.**

- **Paket**:
    - Port: `dev.agitrubard.hexalayered.[module].port`
    - Adapter: `dev.agitrubard.hexalayered.[module].port.adapter`
- **Girdi**: Domain Nesnesi veya özel sarmalayıcı nesneler | `Ticket` veya `Long` veya `String` vb.
- **Çıktı**: Domain Nesnesi veya özel sarmalayıcı nesneler | `Ticket` veya `Long` veya `String` vb.
- **İletişim**:
    - Port arayüzleri service uygulamaları tarafından çağrılır
    - Adapter'lar (port uygulamaları) repository katmanı ile iletişim kurar.
- **Erişim Belirleyici**:
    - Port arayüzleri `public` olmalıdır
    - Adapter sınıfları `package-private` olmalıdır

**Örnek:**

```java
package dev.agitrubard.hexalayered.ticket.port;

public interface TicketSavePort {

    Ticket save(Ticket ticket);

}
```

```java
package dev.agitrubard.hexalayered.ticket.port.adapter;

class TicketSaveAdapter implements TicketSavePort {

    private final TicketRepository ticketRepository;

    TicketSaveAdapter(TicketRepository ticketRepository) {
        this.ticketRepository = ticketRepository;
    }

    @Override
    public Ticket save(Ticket ticket) {
        TicketEntity entity = TicketToEntityMapper.map(ticket);
        TicketEntity savedEntity = ticketRepository.save(entity);
        return TicketEntityToDomainMapper.map(savedEntity);
    }
}
```

### 4. Repository Katmanı

**Veritabanı işlemlerini gerçekleştirir, entity nesneleri üzerinde CRUD işlemlerini yönetir.**

- **Paket**: `dev.agitrubard.hexalayered.[module].repository`
- **Girdi**: Entity Nesnesi veya özel sarmalayıcı nesneler | `TicketEntity` veya `Long` veya `String` vb.
- **Çıktı**: Entity Nesnesi veya özel sarmalayıcı nesneler | `TicketEntity` veya `Long` veya `String` vb.
- **İletişim**: Adapter'lar (port uygulamaları) tarafından çağrılır.
- **Erişim Belirleyici**: `public`

**Örnek:**

```java
package dev.agitrubard.hexalayered.ticket.repository;

public interface TicketRepository extends JpaRepository<TicketEntity, Long> {
}
```

---

## İsimlendirme Kuralları

1. **Controller**:
    - Paket: `dev.agitrubard.hexalayered.[module].controller`
    - Sınıf: `[Domain]Controller` | `TicketController`, `InstitutionController`

2. **Service**:
    - Paket:
        - Arayüz Paketi: `dev.agitrubard.hexalayered.[module].service`
        - Uygulama Paketi: `dev.agitrubard.hexalayered.[module].service.impl`
    - Arayüz: `[Domain][Action]Service` | `TicketCreationService`, `InstitutionUpdateService`
    - Uygulama: `[Domain][Action]ServiceImpl` | `TicketCreationServiceImpl`, `InstitutionUpdateServiceImpl`

3. **Port & Adapter**:
    - Paket:
        - Arayüz Paketi: `dev.agitrubard.hexalayered.[module].port`
        - Uygulama Paketi: `dev.agitrubard.hexalayered.[module].port.adapter`
    - Arayüz: `[Domain][Action]Port` | `TicketSavePort`, `InstitutionReadPort`
    - Uygulama: `[Domain][Action]Adapter` | `TicketSaveAdapter`, `InstitutionReadAdapter`

4. **Repository**:
    - Paket: `dev.agitrubard.hexalayered.[module].repository`
    - Arayüz: `[Domain]Repository` | `TicketRepository`, `InstitutionRepository`

5. **Domain Model**:
    - Paket: `dev.agitrubard.hexalayered.[module].model`
    - Sınıf: `[Domain]` | `Ticket`, `Institution`

6. **Entity**:
    - Paket: `dev.agitrubard.hexalayered.[module].model.entity`
    - Sınıf: `[Domain]Entity` | `TicketEntity`, `InstitutionEntity`

7. **Request**:
    - Paket: `dev.agitrubard.hexalayered.[module].model.request`
    - Sınıf: `[Domain][Action]Request` | `TicketCreateRequest`, `InstitutionUpdateRequest`

8. **Response**:
    - Paket: `dev.agitrubard.hexalayered.[module].model.response`
    - Sınıf: `[Domain]Response` veya `[Domain][Action]Response` | `TicketResponse`, `InstitutionResponse`

9. **Exception**:
    - Paket: `dev.agitrubard.hexalayered.[module].exception`
    - Sınıf: `[ErrorAction]Exception` | `TicketNotFoundByIdException`

10. **Util**:
    - Paket: `dev.agitrubard.hexalayered.[module].util`
    - Sınıf: `[Name]Util` veya `[Name][Action]Util` veya `[Domain][Action]` | `FileUtil` veya `FileReadUtil` veya
      `TicketCodeGenerator`

---

## Avantajlar ve Çözülen Problemler

**1. Entity Bağımlılığının Azaltılması**:

- Domain nesnelerinin kullanımını ön plana çıkararak, entity nesnelerinin uygulama genelinde kullanılmasını önler.
- Entity nesneleri adapter katmanından dışarı çıkamaz, böylece veritabanı yapısı değiştiğinde uygulamanın geri kalanı
  etkilenmez.

**2. Modülerlik ve İzolasyon**:

- Her modül kendi içinde bağımsızdır ve diğer modüllerden izole edilmiştir.
- Değişiklikler yalnızca ilgili modülü etkiler, diğer modüller etkilenmez.

**3. Modüler Port, Adapter ve Service Yapısı**:

- Her işlev için ayrı port, adapter ve service sınıfları oluşturulabilir.
- Bu yapı, Tek Sorumluluk Prensibini (SRP) destekler ve kod tekrarını azaltır.

**4. Temiz Mimari**:

- İç ve dış katmanları net bir şekilde ayırır.
- Bağımlılıklar içten dışa doğrudur, dış katmanlar iç katmanlara bağımlı değildir.

**5. Kolay Test Edilebilirlik**:

- Her katman bağımsız olarak test edilebilir.
- Mock nesneler kullanılarak izole testler yazılabilir.

**6. DDD Uyumluluğu**:

- Domain-Driven Design prensiplerinin uygulanmasını kolaylaştırır.
- Domain nesneleri, uygulamanın merkezinde yer alır.

**7. Esneklik ve Değiştirilebilirlik**:

- Dış sistemlerle etkileşim, Port/Adapter Katmanı üzerinden kolayca değiştirilebilir.
- Yeni özellikler eklemek veya mevcut özellikleri değiştirmek daha kolaydır.

---

## En İyi Uygulamalar

1. **Katman İzolasyonu**: Her katmanın kendi sorumluluğunu yerine getirmesini ve diğer katmanların detaylarından izole
   olmasını sağlayın.
2. **Domain Nesnelerinin Merkeziliği**: Domain nesnelerini uygulamanın merkezine koyun ve iş mantığını bu nesneler
   üzerinden yürütün.
3. **Bağımlılık Enjeksiyonu**: Katmanlar arası bağımlılıkları yönetmek için Dependency Injection (DI) kullanın.
4. **İsimlendirme Tutarlılığı**: Belirlenen isimlendirme standartlarına sıkı sıkıya bağlı kalın. Bu, kodun
   okunabilirliğini ve bakımını kolaylaştırır.
5. **Modüler Yapıyı Koruma**: Her modülün kendi içinde bağımsız olmasını sağlayın. Modüller arası bağımlılıkları
   minimumda tutun.
6. **Port ve Adapter Ayrımı**: Her port için ayrı bir adapter oluşturun. Bu, farklı implementasyonlar arasında geçiş
   yapabilmeyi kolaylaştırır.
7. **Service Modülerliği**: Servisleri, tek bir sorumluluğu olacak şekilde ince granüler yapıda tasarlayın.
8. **Exception Yönetimi**: Her katman için özel exception sınıfları oluşturun ve bunları uygun şekilde yönetin.
9. **Validasyon**: İş kuralı validasyonlarını service katmanında, input validasyonlarını controller katmanında yapın.
10. **Mapper Kullanımı**: Farklı katmanlar arasındaki nesne dönüşümleri için özel mapper sınıfları kullanın.
11. **Değişmez Nesneler**: Mümkün olduğunca immutable nesneler kullanın, özellikle domain nesneleri için.
12. **Dokümantasyon**: Her modül, servis ve önemli sınıf için yeterli dokümantasyon sağlayın.

---

## Modüler Yapı

HexaLayered Mimari, uygulamayı farklı iş alanlarına göre modüllere ayırır. Her modül yukarıda belirtilen katmanları
içerir.

Aşağıda, Common, Ticket ve Institution modüllerini içeren bir uygulama yapısı örneği verilmiştir:

```
dev.agitrubard.hexalayered
├── common
│   │
│   ├── configuration
│   │   └── DataSourceConfiguration
│   │
│   ├── exception
│   │   ├── handler
│   │   │   └── GlobalExceptionHandler
│   │   ├── AbstractNotFoundException
│   │   ├── AbstractServerException
│   │   └── FileReadException
│   │
│   ├── model
│   │   ├── entity
│   │   │   └── BaseEntity
│   │   ├── mapper
│   │   │   └── BaseMapper
│   │   ├── response
│   │   │   ├── ErrorResponse
│   │   │   └── SuccessResponse
│   │   └── BaseDomainModel
│   │
│   └── util
│       ├── FileUtil
│       └── ListUtil
│
│
├── ticket
│   │
│   ├── controller
│   │   └── TicketController
│   │
│   ├── exception
│   │   └── TicketNotFoundByIdException
│   │
│   ├── service
│   │   ├── TicketCreateService
│   │   ├── TicketUpdateService
│   │   ├── TicketDeleteService
│   │   └── impl
│   │       ├── TicketCreateServiceImpl
│   │       ├── TicketUpdateServiceImpl
│   │       └── TicketDeleteServiceImpl
│   │
│   ├── port
│   │   ├── TicketSavePort
│   │   ├── TicketReadPort
│   │   ├── TicketDeletePort
│   │   └── adapter
│   │       ├── TicketSaveAdapter
│   │       ├── TicketReadAdapter
│   │       └── TicketDeleteAdapter
│   │
│   ├── repository
│   │   └── TicketRepository
│   │
│   ├── model
│   │   ├── entity
│   │   │   └── TicketEntity
│   │   ├── enums
│   │   │   └── TicketStatus
│   │   ├── mapper
│   │   │   ├── TicketToEntityMapper
│   │   │   └── TicketEntityToDomainMapper
│   │   ├── request
│   │   │   ├── TicketCreateRequest
│   │   │   └── TicketUpdateRequest
│   │   ├── response
│   │   │   └── TicketResponse
│   │   └── Ticket
│   │
│   └── util
│       └── TicketCodeGenerator
│
│
└── institution
    │
    ├── controller
    │   └── InstitutionController
    │
    ├── exception
    │   ├── InstitutionAlreadyExistByNameException
    │   └── InstitutionNotFoundByIdException
    │
    ├── service
    │   ├── InstitutionService
    │   └── impl
    │       └── InstitutionServiceImpl
    │
    ├── port
    │   ├── InstitutionSavePort
    │   ├── InstitutionReadPort
    │   ├── InstitutionDeletePort
    │   └── adapter
    │       └── InstitutionAdapter
    │
    ├── repository
    │   └── InstitutionRepository
    │
    └── model
        ├── entity
        │   └── InstitutionEntity
        ├── enums
        │   └── InstitutionStatus
        ├── mapper
        │   ├── InstitutionToEntityMapper
        │   └── InstitutionEntityToDomainMapper
        ├── request
        │   ├── InstitutionCreateRequest
        │   └── InstitutionUpdateRequest
        ├── response
        │   └── InstitutionResponse
        └── Institution
```

---

## Kullanılan Projeler

HexaLayered Architecture'ın gerçek dünya uygulamalarını görmek için aşağıdaki açık kaynak projeleri inceleyebilirsiniz:

### 1. Afet Yönetim Sistemi | AYS APIs

**Bu proje, HexaLayered Architecture'ın karmaşık ve kritik sistemlerde nasıl uygulandığını göstermektedir.**

https://github.com/afet-yonetim-sistemi/ays-be

- Modüler yapı
- Uçtan uca hata yönetimi
- Genişletilmiş arama ve filtreleme özellikleri
- Kapsamlı test altyapısı
- Gelişmiş güvenlik ve yetkilendirme özellikleri

### 2. Gelecek Bilimde Community Science Communication Platform APIs

Bu proje, HexaLayered Architecture'ın içerik yönetimi ve API tasarımında nasıl kullanıldığını göstermektedir.

https://github.com/gelecekbilimde/backend

- Modüler yapı
- Uçtan uca hata yönetimi
- Genişletilmiş arama ve filtreleme özellikleri
- Güvenlik ve yetkilendirme özellikleri

Bu projeler, HexaLayered Architecture'ın farklı kullanım senaryolarında nasıl uygulandığını göstermektedir. Her iki
proje de açık kaynak olduğundan, kodlarını inceleyebilir ve mimarinin pratik uygulamalarını detaylı olarak
görebilirsiniz.

> Eğer siz de HexaLayered Architecture'ı kullanan bir proje geliştirdiyseniz ve burada listelemek isterseniz, lütfen
> bildirin!

---

## Katkıda Bulunma

HexaLayered Mimari'yi geliştirmek ve iyileştirmek için birlikte çalışabiliriz. Katkıda bulunmak
için [CONTRIBUTING.md](../../../CONTRIBUTING.md) dosyasını inceleyebilirsiniz.

---

## Lisans

Bu proje MIT Lisansı altında lisanslanmıştır. Detaylar için [LICENSE](../../../LICENSE) dosyasına bakınız.

---

## SSS (Sıkça Sorulan Sorular)

**1. HexaLayered Mimari'yi mevcut projeme nasıl entegre edebilirim?**

```
Mevcut projenizi aşamalı olarak HexaLayered Mimari'ye geçirebilirsiniz. Yeni modülleri bu mimari ile geliştirmeye başlayın ve zamanla mevcut modülleri dönüştürün. Uygulamanızın en izole bölümlerinden başlayıp daha entegre bileşenlere doğru ilerleyin.
```

**2. HexaLayered Mimari mikroservis mimarisi ile uyumlu mu?**

```
Evet, HexaLayered Mimari mikroservislerle oldukça uyumludur. Her mikroservis, HexaLayered Mimari'yi dahili olarak uygulayabilir. Bu, mikroservisler ekosisteminiz genelinde tutarlı bir yapı sağlarken, servisler arasında gevşek bağlantıyı korur.
```

**3. HexaLayered Mimari test edilebilirliği nasıl artırır?**

```
HexaLayered Mimari, endişeleri ve bağımlılıkları net bir şekilde ayırarak test edilebilirliği artırır. Her katman, bağımlılıkları için mock veya stub kullanılarak izole bir şekilde test edilebilir. Bu, daha odaklı birim testlere, daha kolay entegrasyon testlerine ve genel olarak daha iyi test kapsamına olanak tanır.
```

**4. Bu mimaride Port'lar ve Adapter'lar arasındaki fark nedir?**

```
Port'lar, uygulamanın dış sistemlerle nasıl etkileşime girdiğini veya dış sistemlerin uygulama ile nasıl etkileşime girdiğini tanımlayan arayüzlerdir. Adapter'lar ise bu arayüzlerin somut uygulamalarıdır. Bu ayrım, temel iş mantığını değiştirmeden uygulamaların kolayca değiştirilmesine olanak tanır.
```

**5. HexaLayered Mimari'de kesişen endişeleri (cross-cutting concerns) nasıl ele alırım?**

```
Loglama, güvenlik ve transaction yönetimi gibi kesişen endişeler, aspect'ler (AOP) kullanılarak veya bu endişeler uygun katmanlarda uygulanarak ele alınabilir. Örneğin, güvenlik kontrolleri Controller katmanında yapılabilirken, transaction yönetimi Service katmanında ele alınabilir.
```

**6. HexaLayered Mimari'yi Spring Boot dışındaki frameworklerle kullanabilir miyim?**

```
Verilen örnekler Spring Boot'ta olsa da, HexaLayered Mimari prensipleri framework'ten bağımsızdır. Bu mimariyi diğer framework'leri kullanan projelerde veya hatta farklı programlama dillerinde de uygulayabilirsiniz, uygulama detaylarını gerektiği gibi uyarlayarak.
```

**7. HexaLayered Mimari, Domain-Driven Design (DDD) prensiplerini nasıl destekler?**

```
HexaLayered Mimari, DDD prensipleriyle iyi uyum sağlar. Domain modeli uygulamanın merkezinde kalır ve dış endişelerden izole edilir. Port ve Adapter katmanları, domain ve altyapı arasında net bir sınır oluşturmaya yardımcı olur, bu da DDD'nin kilit bir yönüdür.
```

**8. HexaLayered Mimari'nin performans üzerindeki etkileri nelerdir?**

```
Genellikle, HexaLayered Mimari'nin performans üzerindeki etkisi minimaldir. Ek katmanlar ve dönüşümler nedeniyle hafif bir overhead getirebilse de, bakım yapılabilirlik ve esneklik açısından sağladığı faydalar genellikle bunu dengeler. Uygun uygulama ve optimizasyon, çoğu performans endişesini azaltabilir.
```

**9. HexaLayered Mimari'de birden fazla servis arasındaki veritabanı işlemlerini nasıl yönetirim?**

```
Birden fazla servisi kapsayan işlemler için Saga pattern veya iki aşamalı commit protokolü gibi dağıtık işlem yönetimi tekniklerini kullanabilirsiniz. Alternatif olarak, servisler arası işlem ihtiyacını en aza indirmek için domain sınırlarınızı yeniden değerlendirebilirsiniz.
```

**10. HexaLayered Mimari küçük projeler için uygun mu?**

```
HexaLayered Mimari orta ve büyük ölçekli projelerde parlasa da, çok küçük uygulamalar için fazla karmaşık olabilir. Ancak, projenizin karmaşıklığının artacağını öngörüyorsanız, bu mimari ile başlamak gelecekteki genişleme için sağlam bir temel oluşturabilir.
```

**11. HexaLayered Mimari'de farklı modüller arasındaki bağımlılıkları nasıl yönetirim?**

```
Modüller arası bağımlılıklar iyi tanımlanmış arayüzler üzerinden yönetilmelidir. Bir modül başka bir modülün işlevselliğine ihtiyaç duyuyorsa, bu bir port (arayüz) üzerinden açığa çıkarılmalı ve bir adapter üzerinden erişilmelidir. Bu, modülerliği korur ve gelecekteki değişiklikleri kolaylaştırır.
```

**12. HexaLayered Mimari'yi event-driven sistemlerle kullanabilir miyim?**

```
Evet, HexaLayered Mimari event-driven sistemlerle iyi çalışır. Event'ler bir tür port olarak değerlendirilebilir ve adapter'lar bu event'lerin yayınlanmasını ve abone olunmasını yönetebilir. Bu, çekirdek domain mantığının, kullanılan event sisteminin detaylarından izole kalmasını sağlar.
```

**13. Çok kapsamlı olmayan bir servisim varsa, yine de Read, Write gibi görevlere göre ayırmalı mıyım?**

```
Bu, servisinizin karmaşıklığına ve potansiyel büyümesine bağlıdır. Daha basit servisler için, okuma ve yazma işlemlerini tek bir servis sınıfında tutmak genellikle kabul edilebilir. Ancak, servisin gelecekte karmaşıklaşabileceğini öngörüyorsanız veya projenizdeki daha büyük servislerle tutarlılık sağlamak istiyorsanız, ayırmak faydalı olabilir.

Temel hususlar:
- Servisin belirgin şekilde ayrı okuma ve yazma mantığı varsa, ayırmak daha temiz olabilir.
- Gelecekte servisin daha karmaşık hale geleceğini öngörüyorsanız, erken ayırma gelecekteki değişiklikleri kolaylaştırabilir.
- Çok basit CRUD işlemleri için tek bir servis daha pragmatik olabilir.
- Projeniz genelindeki tutarlılık önemlidir. Diğer servisler ayrılmışsa, aynı deseni korumak geliştirici aşinalığı açısından faydalı olabilir.

Unutmayın, amaç temiz mimari prensiplerini pratik geliştirme ihtiyaçlarıyla dengelemektir. Tek bir servis ile başlayıp, gerektiğinde daha sonra refactor etmek de kabul edilebilir bir yaklaşımdır.
```

**14. Çok kapsamlı olmayan bir port/adapter'ım varsa, yine de Read, Write gibi görevlere göre ayırmalı mıyım?**

```
Servislere benzer şekilde, port ve adapter'ları ayırma kararı, işlemlerin karmaşıklığına ve gelecekteki büyüme potansiyeline bağlıdır.

İşte bazı yönergeler:
- Basit CRUD işlemleri için tek bir port/adapter çifti yeterli olabilir. Örneğin, bir TicketPort ve TicketAdapter tüm temel işlemleri yönetebilir.
- Okuma ve yazma işlemleri önemli ölçüde farklı endişelere sahipse (örneğin, farklı dış sistemler, önbellekleme stratejileri veya işlem gereksinimleri), ayırmak faydalı olabilir.
- Tek Sorumluluk Prensibini (SRP) göz önünde bulundurun. Okuma ve yazma işlemlerinin ayrı sorumlulukları varsa veya bağımsız olarak evrimleşebileceklerse, ayırmak kodu daha bakımı kolay hale getirebilir.
- Test etmeyi düşünün: okuma ve yazma işlemlerini ayırmak testlerinizi daha temiz ve odaklı hale getirecekse, bunu yapmaya değer olabilir.
- Service katmanınızla tutarlılığı düşünün. Servislerinizi okuma ve yazma olarak ayırdıysanız, bunu port ve adapter'larınıza da yansıtmak mantıklı olabilir.

Sonuç olarak, karar sizin özel kullanım durumunuza, domain'inizin karmaşıklığına ve ekibinizin tercihlerine dayanmalıdır. Tek bir port/adapter ile başlayıp, ihtiyaç ortaya çıktığında daha sonra refactor etmek de tamamen kabul edilebilir bir yaklaşımdır. Önemli olan, kodunuzu organize, bakımı kolay ve projenizin genel mimarisiyle uyumlu tutmaktır.
```

**15. Farklı işlemler için ayrı sınıflar oluşturmaya veya bunları tek bir sınıfta tutmaya ne zaman karar vermeliyim?**

```
Bu karar hem servisler hem de port/adapter'lar için geçerlidir.

Aşağıdaki faktörleri göz önünde bulundurun:

1. Karmaşıklık: Farklı işlemler (örn. okuma, yazma, güncelleme) için mantık karmaşık ve belirgin şekilde farklıysa, ayrı sınıflar daha net olabilir.

2. Boyut: Tek bir sınıf çok büyük hale geliyorsa (örn. 300 satırdan fazla), bölme zamanı gelmiş olabilir.

3. Değişim sıklığı: Belirli işlemler diğerlerinden daha sık değişiyorsa, bunları ayırmak değişiklikleri izole edebilir.

4. Yeniden kullanılabilirlik: Bazı işlemler farklı bağlamlarda yeniden kullanılıyorsa, bunları ayırmak kod tekrarını azaltabilir.

5. Ekip yapısı: Farklı ekip üyeleri veya ekipler farklı işlemlerden sorumluysa, ayırma paralel geliştirmeye yardımcı olabilir.

6. Performans: Bazı durumlarda, okuma ve yazma işlemlerini ayırmak, her birini kendi özel ihtiyaçları için optimize etmeye yardımcı olabilir (örn. okuma optimizasyonu vs. yazma tutarlılığı).

Unutmayın, HexaLayered Mimari'nin amacı temiz, bakımı kolay ve esnek bir kod tabanı oluşturmaktır. Granülerlik seviyesi, gereksiz karmaşıklık getirmeden bu amaca hizmet etmelidir.
```

**16. Her zaman interface oluşturmalı mıyım? Interface oluşturmazsam ne olur?**

```
HexaLayered Mimari'de, tüm katmanlar arasındaki iletişim için interface'ler kullanılmalıdır. 
Bu yaklaşım, ihtiyaç olup olmadığına bakılmaksızın uygulanmalıdır. 

Nedenleri:
1. Soyutlama: Interface'ler, implementasyondan bağımsız bir soyutlama katmanı sağlar.
2. Esneklik: Gelecekteki değişikliklere ve farklı implementasyonlara olanak tanır.
3. Test Edilebilirlik: Mock objelerin kolayca oluşturulmasını sağlar.
4. Bağımlılık Yönetimi: Katmanlar arası bağımlılıkları azaltır.
5. Mimari Tutarlılık: Tüm katmanlar arasında tutarlı bir iletişim yapısı oluşturur.

Interface kullanmamak, bu avantajları kaybetmenize ve mimarinin temel prensiplerinden uzaklaşmanıza neden olur. HexaLayered Mimari'nin başarısı için, tüm katmanlar arasında interface kullanımı kritik öneme sahiptir.
```
