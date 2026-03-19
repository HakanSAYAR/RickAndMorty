//
//  CharacterEntityTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterEntityTests

struct CharacterEntityTests {

    // MARK: - Equality

    @Test func equality_basedOnId() {
        let a = Character.stub(id: 1, name: "Rick")
        let b = Character.stub(id: 1, name: "Rick Sanchez")
        #expect(a == b)
    }

    @Test func inequality_differentIds() {
        let a = Character.stub(id: 1)
        let b = Character.stub(id: 2)
        #expect(a != b)
    }

    // MARK: - Hashing

    @Test func hash_basedOnId() {
        let a = Character.stub(id: 42)
        let b = Character.stub(id: 42, name: "Other")
        var setA = Hasher(); a.hash(into: &setA)
        var setB = Hasher(); b.hash(into: &setB)
        #expect(setA.finalize() == setB.finalize())
    }

    // MARK: - Properties

    @Test func properties_areStoredCorrectly() {
        let character = Character.stub(
            id: 7,
            name: "Morty Smith",
            status: .alive,
            species: "Human",
            gender: .male,
            originName: "Earth (C-137)",
            locationName: "Earth (Replacement Dimension)",
            image: "https://example.com/morty.jpg"
        )
        #expect(character.id == 7)
        #expect(character.name == "Morty Smith")
        #expect(character.status == .alive)
        #expect(character.species == "Human")
        #expect(character.gender == .male)
        #expect(character.origin.name == "Earth (C-137)")
        #expect(character.location.name == "Earth (Replacement Dimension)")
        #expect(character.image == "https://example.com/morty.jpg")
    }

    // MARK: - CharacterStatus

    @Test func status_displayText_alive() {
        #expect(CharacterStatus.alive.displayText == "Alive")
    }

    @Test func status_displayText_dead() {
        #expect(CharacterStatus.dead.displayText == "Dead")
    }

    @Test func status_displayText_unknown() {
        #expect(CharacterStatus.unknown.displayText == "unknown")
    }

    // MARK: - CharacterGender

    @Test func gender_displayText_male() {
        #expect(CharacterGender.male.displayText == "Male")
    }

    @Test func gender_displayText_female() {
        #expect(CharacterGender.female.displayText == "Female")
    }

    @Test func gender_displayText_genderless() {
        #expect(CharacterGender.genderless.displayText == "Genderless")
    }

    @Test func gender_displayText_unknown() {
        #expect(CharacterGender.unknown.displayText == "unknown")
    }

    // MARK: - CharacterLocation

    @Test func location_storesName() {
        let location = CharacterLocation(name: "Citadel of Ricks")
        #expect(location.name == "Citadel of Ricks")
    }
}
