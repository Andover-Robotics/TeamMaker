import pandas as pd
from process_experiences import experiences

df = pd.read_csv('2020-2021 ARC Member Info  (Responses) - Form Responses 1.csv')

df['Name'] = df['First Name'].apply(str.strip) + ' ' + df['Last Name'].apply(str.strip)
del df['First Name']
del df['Last Name']

collapse_gender = lambda gender: 'Male' if gender.startswith('Male') else 'Female'
df['Gender'] = df['Gender'].apply(collapse_gender)

fix_grade = lambda grade: int(grade.replace('th', ''))
df['Grade'] = df['Grade'].apply(fix_grade)

column_replace = {
    "Cohort": "Cohort",
    'Expertise - [Mechanical]': 'Strength.Mechanical',
    'Expertise - [Programming]': 'Strength.Software',
    'Expertise - [Outreach]': 'Strength.Outreach',
    'Expertise - [Engineering Notebook]': 'Strength.Notebook',
    'Expertise - [Physics]': 'Strength.Physics',
    'Expertise - [CAD]': 'Strength.CAD',
    'Team Preference - [Hailstorm 10331]': 'Preference.Hailstorm',
    'Team Preference - [Thunder 5273]': 'Preference.Thunder',
    'Team Preference [Lightning  4410]': 'Preference.Lightning',
    'Commitment Level:': 'Commitment'
}

replaced_column = lambda original: column_replace.get(original, original)
df.columns = df.columns.map(replaced_column)

for col in df.columns:
    if col.startswith('Strength') or col.startswith('Preference'):
        df[col] = df[col].apply(lambda x: int(x.split('(')[0].strip() if type(x) == str else x)/10)
    elif col.startswith('Commitment'):
        df[col] = df[col].apply(lambda x: int(x)/5)


df['Experience'] = df['Name'].apply(experiences.get)

import random
possible_teams = lambda name: ['Hailstorm', 'Thunder', 'Lightning'] if df[df.Name == name].Gender.iloc[0] == 'Female' else ['Thunder', 'Lightning']
def init_team(name):
    teams = possible_teams(name)
    prefs = [df[df.Name == name][f'Preference.{team}'].iloc[0] for team in teams]
    return random.choice([teams[idx] for idx, pref in enumerate(prefs) if pref == max(prefs)])

df['Team'] = df['Name'].apply(init_team)

def balance_prefs(name):
    columns = [f'Preference.{team}' for team in possible_teams(name)]
    prefs = df.loc[df.Name == name, columns].to_numpy()
    prefs += (0.5 - prefs.mean())
    df.loc[df.Name == name, columns] = prefs

for name in df.Name:
    balance_prefs(name)

df.to_csv('members2020.csv', index=False)