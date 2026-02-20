import json
import os
import glob

def main():
    l10n_dir = '/Users/ace/my_first_project/lib/l10n'
    arb_files = glob.glob(os.path.join(l10n_dir, '*.arb'))
    
    # Metadata for placeholders
    metadata = {
        "@notificationsCount": {"placeholders": {"count": {"type": "int"}}},
        "@matchCount": {"placeholders": {"count": {"type": "int"}}},
        "@likesCount": {"placeholders": {"count": {"type": "int"}}},
        "@photosCount": {"placeholders": {"count": {"type": "int"}}},
        "@distanceKm": {"placeholders": {"count": {"type": "int"}}}
    }

    english_plurals = {
        "@@_PLURALS_NEW": "New plural items added",
        "notificationsCount": "{count, plural, =0{No notifications} =1{1 notification} other{{count} notifications}}",
        "matchCount": "{count, plural, =0{No matches} =1{1 match} other{{count} matches}}",
        "likesCount": "{count, plural, =0{No likes} =1{1 like} other{{count} likes}}",
        "photosCount": "{count, plural, =0{No photos} =1{1 photo} other{{count} photos}}",
        "distanceKm": "{count, plural, =0{Less than 1 km away} =1{1 km away} other{{count} km away}}"
    }

    arabic_plurals = {
        "@@_PLURALS_NEW": "New plural items added",
        "notificationsCount": "{count, plural, =0{لا توجد إشعارات} =1{إشعار واحد} =2{إشعاران} few{{count} إشعارات} many{{count} إشعاراً} other{{count} إشعار}}",
        "matchCount": "{count, plural, =0{لا توجد تطابقات} =1{تطابق واحد} =2{تطابقان} few{{count} تطابقات} many{{count} تطابقاً} other{{count} تطابق}}",
        "likesCount": "{count, plural, =0{لا توجد إعجابات} =1{إعجاب واحد} =2{إعجابين} few{{count} إعجابات} many{{count} إعجاباً} other{{count} إعجاب}}",
        "photosCount": "{count, plural, =0{لا توجد صور} =1{صورة واحدة} =2{صورتان} few{{count} صور} many{{count} صورة} other{{count} صورة}}",
        "distanceKm": "{count, plural, =0{أقل من 1 كم} =1{1 كم} =2{2 كم} few{{count} كم} many{{count} كم} other{{count} كم}}"
    }

    russian_plurals = {
        "@@_PLURALS_NEW": "New plural items added",
        "notificationsCount": "{count, plural, =0{Нет уведомлений} =1{1 уведомление} few{{count} уведомления} many{{count} уведомлений} other{{count} уведомлений}}",
        "matchCount": "{count, plural, =0{Нет совпадений} =1{1 совпадение} few{{count} совпадения} many{{count} совпадений} other{{count} совпадений}}",
        "likesCount": "{count, plural, =0{Нет лайков} =1{1 лайк} few{{count} лайка} many{{count} лайков} other{{count} лайков}}",
        "photosCount": "{count, plural, =0{Нет фото} =1{1 фото} few{{count} фото} many{{count} фото} other{{count} фото}}",
        "distanceKm": "{count, plural, =0{Меньше 1 км} =1{1 км} few{{count} км} many{{count} км} other{{count} км}}"
    }

    for file in arb_files:
        with open(file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if 'notificationsCount' in data:
            continue # already added

        locale = data.get('@@locale', 'en')
        
        # Merge dictionaries
        if locale == 'ar':
            data.update(arabic_plurals)
        elif locale == 'ru':
            data.update(russian_plurals)
        else:
            data.update(english_plurals) # fallback to English format for others to ensure compilation works

        data.update(metadata)

        with open(file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            
    print("Plurals injected into all ARB files.")

if __name__ == '__main__':
    main()
